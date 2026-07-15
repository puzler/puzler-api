module Patreon
  # Creator-side sync: detect whether the linked user owns a campaign, mirror
  # it with its tiers, and keep our per-campaign webhook registered. Runs on
  # link (async), from the syncPatreonCampaign mutation, and from the daily
  # reconcile. Token failures mark the campaign token_stale (cached entitlement
  # keeps serving) instead of raising to the caller.
  class SyncCreatorCampaign
    WEBHOOK_TRIGGERS = %w[
      members:create members:update members:delete
      members:pledge:create members:pledge:update members:pledge:delete
    ].freeze

    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    # Returns the up-to-date PatreonCampaign, or nil when the user isn't a
    # creator (or we couldn't reach Patreon).
    def call
      identity = @user.oauth_identities.find_by(provider: "patreon")
      return nil unless identity&.scopes.to_s.split.include?("campaigns")

      campaign_data = Token.with_retry(identity) { |client| client.campaigns }["data"]&.first
      existing = @user.patreon_campaign

      if campaign_data.nil?
        # Linked and queryable, but no campaign: not a creator (anymore).
        existing.update!(status: :removed) if existing && !existing.status_removed?
        return nil
      end

      campaign = upsert_campaign(existing, campaign_data)
      sync_tiers(identity, campaign)
      ensure_webhook(identity, campaign)
      campaign
    rescue Token::RefreshFailed
      @user.patreon_campaign&.update!(status: :token_stale)
      nil
    end

    private

    def upsert_campaign(existing, data)
      attrs = data["attributes"] || {}
      campaign = existing || @user.build_patreon_campaign
      campaign.assign_attributes(
        patreon_id: data["id"],
        title: attrs["creation_name"].presence || campaign.title,
        url: attrs["url"].presence || campaign.url,
        currency: attrs["currency"].presence || campaign.currency,
        status: :active, # any successful sync recovers token_stale/disconnected
        campaign_synced_at: Time.current
      )
      campaign.save!
      campaign
    end

    def sync_tiers(identity, campaign)
      body = Token.with_retry(identity) { |client| client.campaign_with_tiers(campaign.patreon_id) }
      tier_resources = (body["included"] || []).select { |resource| resource["type"] == "tier" }

      seen = tier_resources.map do |resource|
        attrs = resource["attributes"] || {}
        tier = campaign.tiers.find_or_initialize_by(patreon_id: resource["id"])
        tier.assign_attributes(
          title: attrs["title"].presence || tier.title || "Untitled tier",
          amount_cents: attrs["amount_cents"].to_i,
          published: attrs.fetch("published", true),
          discarded_at: nil # a tier reappearing on Patreon is resurrected
        )
        tier.save!
        tier.id
      end

      # Tiers gone from Patreon are discarded, never destroyed: gates reference
      # them and the min-tier fallback needs the recorded price.
      campaign.tiers.kept.where.not(id: seen).find_each(&:discard!)
    end

    # Register (or unpause) the members webhook so entitlement changes land
    # without waiting for the daily reconcile.
    def ensure_webhook(identity, campaign)
      return unless identity.scopes.to_s.split.include?("w:campaigns.webhook")

      if campaign.webhook_patreon_id.blank?
        api_url = ENV.fetch("API_URL", "http://localhost:3000")
        body = Token.with_retry(identity) do |client|
          client.create_webhook(campaign.patreon_id,
            uri: "#{api_url}/webhooks/patreon/#{campaign.id}",
            triggers: WEBHOOK_TRIGGERS)
        end
        campaign.update!(
          webhook_patreon_id: body.dig("data", "id"),
          webhook_secret: body.dig("data", "attributes", "secret")
        )
      elsif campaign.webhook_paused_at.present?
        # Patreon pauses hooks after repeated failures; unpausing replays the
        # queued events.
        Token.with_retry(identity) { |client| client.update_webhook(campaign.webhook_patreon_id, paused: false) }
        campaign.update!(webhook_paused_at: nil)
      end
    rescue Client::Error
      # Webhook management is best-effort: the daily reconcile is the backstop.
      nil
    end
  end
end
