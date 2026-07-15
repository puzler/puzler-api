module Types
  module Objects
    # The owner-facing mirror of a creator's Patreon campaign. Only ever
    # resolved for the campaign's own user (UserType gates it self-only).
    class PatreonCampaignType < BaseObject
      description "The current user's linked Patreon campaign (creator side)"

      field :campaign_synced_at, GraphQL::Types::ISO8601DateTime, null: true,
        description: "When the campaign and tiers were last mirrored from Patreon"
      field :currency, String, null: true, description: "Campaign currency code (e.g. USD)"
      field :id, ID, null: false, description: "Puzler's ID for the mirrored campaign"
      field :members_synced_at, GraphQL::Types::ISO8601DateTime, null: true,
        description: "When the full member list was last reconciled"
      field :status, Types::Enums::PatreonCampaignStatusEnum, null: false,
        description: "Link health: active, token_stale (reconnect recommended), disconnected, or removed"
      field :teasers_enabled, Boolean, null: false,
        description: "Whether non-patrons see locked previews of this campaign's gated content"
      field :tiers, [ PatreonTierType ], null: false,
        description: "The campaign's tiers (kept ones only), cheapest first"
      field :title, String, null: true, description: "Campaign name on Patreon"
      field :url, String, null: true, description: "The campaign's patreon.com page"
      field :webhook_active, Boolean, null: false,
        description: "Whether our member webhook is registered and unpaused"

      def tiers
        object.tiers.kept.by_amount
      end

      def webhook_active
        object.webhook_patreon_id.present? && object.webhook_paused_at.nil?
      end
    end
  end
end
