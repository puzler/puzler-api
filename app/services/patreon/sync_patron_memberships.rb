module Patreon
  # Patron-side sync: pull the linked user's memberships across all campaigns
  # they support and mirror the ones that belong to Puzler creators. Runs on
  # link (async), from the explicit refresh mutation, and from the throttled
  # on-demand freshness path. Raises Token::RefreshFailed when the user must
  # re-run OAuth; callers decide how to surface that.
  class SyncPatronMemberships
    def self.call(user, source: :oauth)
      new(user, source:).call
    end

    def initialize(user, source:)
      @user = user
      @source = source
    end

    def call
      identity = @user.oauth_identities.find_by(provider: "patreon")
      return false unless identity&.scopes.to_s.split.include?("identity.memberships")

      body = Token.with_retry(identity) { |client| client.identity_with_memberships }

      seen_campaign_ids = []
      members_in(body).each do |member|
        campaign_patreon_id = member.dig("relationships", "campaign", "data", "id")
        campaign = PatreonCampaign.find_by(patreon_id: campaign_patreon_id)
        next unless campaign # supports a creator who isn't on Puzler

        MembershipUpsert.apply(user: @user, campaign:, member:, source: @source)
        seen_campaign_ids << campaign.id
      end

      # Memberships we hold that Patreon no longer reports have ended.
      @user.patreon_memberships.active.where.not(patreon_campaign_id: seen_campaign_ids)
        .find_each { |membership| MembershipUpsert.demote!(membership) }

      true
    end

    private

    def members_in(body)
      (body["included"] || []).select { |resource| resource["type"] == "member" }
    end
  end
end
