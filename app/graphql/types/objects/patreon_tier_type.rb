module Types
  module Objects
    class PatreonTierType < BaseObject
      description "A reward tier on a creator's Patreon campaign, mirrored from the API"

      field :amount_cents, Integer, null: false,
        description: "The tier's price in the campaign currency's minor units"
      field :discarded, Boolean, null: false, method: :discarded?,
        description: "Whether this tier has been deleted on Patreon (kept here because gates may reference it)"
      field :id, ID, null: false, description: "Puzler's ID for the mirrored tier"
      field :patreon_id, String, null: false, description: "Patreon's stable tier ID"
      field :published, Boolean, null: false, description: "Whether the tier is published on Patreon"
      field :title, String, null: false, description: "Tier name as shown on Patreon"
    end
  end
end
