module Types
  module InputObjects
    class PatronGateInput < GraphQL::Schema::InputObject
      description "Patron gate configuration for a patrons-only puzzle or collection"

      argument :min_amount_cents, Integer, required: false,
        description: "Minimum pledge in the campaign currency's minor units (min_amount mode)"
      argument :min_tier_id, ID, required: false,
        description: "Puzler ID of the minimum qualifying tier (min_tier mode); omit for any paying patron"
      argument :mode, Types::Enums::PatronGateModeEnum, required: true,
        description: "How qualification is decided: min_tier, tier_list, or min_amount"
      argument :patrons_since_release, Boolean, required: false, default_value: false,
        description: "Back-catalog lock: only patrons who were already supporting at release time qualify"
      argument :tier_ids, [ ID ], required: false,
        description: "Puzler IDs of the qualifying tiers (tier_list mode; any number)"
    end
  end
end
