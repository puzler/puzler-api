module Patreon
  # Receives Patreon's per-campaign member webhooks. Fast and forgiving on
  # purpose: unexpected payload shapes log and 200, because repeated non-2xx
  # responses make Patreon pause the webhook (the daily reconcile then becomes
  # our only feed). Signature mismatches are the one deliberate 4xx; truly
  # malformed JSON is 400'd by Rails' params middleware before we run, which
  # is fine — Patreon doesn't send it.
  class WebhooksController < ApplicationController
    MEMBER_EVENTS = %w[
      members:create members:update members:delete
      members:pledge:create members:pledge:update members:pledge:delete
    ].freeze

    def create
      campaign = PatreonCampaign.find_by(id: params[:campaign_id])
      return head :not_found unless campaign&.webhook_secret.present?

      return head :unauthorized unless valid_signature?(campaign)

      handle_event(campaign, request.headers["X-Patreon-Event"].to_s)
      head :ok
    rescue JSON::ParserError, KeyError, TypeError => e
      Rails.logger.warn("Patreon webhook payload error (campaign #{params[:campaign_id]}): #{e.message}")
      head :ok
    end

    private

    # X-Patreon-Signature is the HMAC-MD5 hex digest of the raw request body,
    # keyed with the secret Patreon returned when the webhook was created.
    # Compare against the RAW body — any re-serialization would change bytes.
    def valid_signature?(campaign)
      signature = request.headers["X-Patreon-Signature"].to_s
      return false if signature.blank?

      expected = OpenSSL::HMAC.hexdigest("MD5", campaign.webhook_secret, request.raw_post)
      ActiveSupport::SecurityUtils.secure_compare(expected, signature)
    end

    def handle_event(campaign, event)
      return unless MEMBER_EVENTS.include?(event)

      member = JSON.parse(request.raw_post)["data"]
      return unless member.is_a?(Hash)

      patreon_user_id = member.dig("relationships", "user", "data", "id")
      linked = UserOauthIdentity.find_by(provider: "patreon", uid: patreon_user_id)
      return unless linked # patron isn't a Puzler user — nothing to store

      if event == "members:delete"
        membership = PatreonMembership.find_by(user_id: linked.user_id, patreon_campaign: campaign)
        MembershipUpsert.demote!(membership) if membership
      else
        MembershipUpsert.apply(user: linked.user, campaign:, member:, source: :webhook)
      end
    end
  end
end
