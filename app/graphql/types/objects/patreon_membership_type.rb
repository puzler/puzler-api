module Types
  module Objects
    # The viewer's own membership in a creator's campaign (patron side). Only
    # ever resolved self-only from UserPatreonType.
    class PatreonMembershipType < BaseObject
      description "The current user's Patreon membership in a Puzler creator's campaign"

      field :campaign, PatreonCampaignRefType, null: false, method: :patreon_campaign,
        description: "The supported campaign"
      field :entitled_amount_cents, Integer, null: false,
        description: "Current pledge entitlement in the campaign currency's minor units"
      field :id, ID, null: false, description: "Membership row ID"
      field :patron_status, Types::Enums::PatronStatusEnum, null: false,
        description: "Standing: active_patron, declined_patron, former_patron, or unknown"
      field :synced_at, GraphQL::Types::ISO8601DateTime, null: false,
        description: "When this membership was last synced from Patreon"
    end
  end
end
