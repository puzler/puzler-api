module Patreon
  # Creator-side member reconciliation: page through the campaign's full member
  # list with the creator's token and mirror every member who is a linked
  # Puzler user. The backstop for missed/paused webhooks — freshness between
  # syncs otherwise degrades to the on-demand path's 15 minutes.
  class ReconcileCampaignMembers
    def self.call(campaign)
      new(campaign).call
    end

    def initialize(campaign)
      @campaign = campaign
    end

    def call
      identity = @campaign.user.oauth_identities.find_by(provider: "patreon")
      return false unless identity&.scopes.to_s.split.include?("campaigns.members")

      seen_user_ids = []
      cursor = nil
      loop do
        body, cursor = Token.with_retry(identity) do |client|
          client.campaign_members(@campaign.patreon_id, cursor:)
        end

        (body["data"] || []).each do |member|
          patreon_user_id = member.dig("relationships", "user", "data", "id")
          linked = UserOauthIdentity.find_by(provider: "patreon", uid: patreon_user_id)
          next unless linked # patron isn't a Puzler user; nothing to grant

          MembershipUpsert.apply(user: linked.user, campaign: @campaign, member:, source: :creator_poll)
          seen_user_ids << linked.user_id
        end

        break if cursor.blank?
      end

      # Active rows absent from the full list have ended on Patreon's side.
      @campaign.memberships.active.where.not(user_id: seen_user_ids)
        .find_each { |membership| MembershipUpsert.demote!(membership) }

      @campaign.update!(members_synced_at: Time.current)
      true
    end
  end
end
