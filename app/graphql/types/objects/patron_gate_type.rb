module Types
  module Objects
    # A patrons_only item's gate config. Deliberately public: the tier names
    # and prices ARE the teaser's marketing copy. Absence of a gate row means
    # the default gate (any paying patron), which resolvers surface as null.
    class PatronGateType < BaseObject
      description "Who qualifies for a patrons-only puzzle or collection"

      field :min_amount_cents, Integer, null: true,
        description: "Minimum pledge in the campaign currency's minor units (min_amount mode)"
      field :min_tier, PatreonTierType, null: true,
        description: "The minimum qualifying tier (min_tier mode); null means any paying patron"
      field :mode, Types::Enums::PatronGateModeEnum, null: false,
        description: "How qualification is decided: min_tier, tier_list, or min_amount"
      field :patrons_since_release, Boolean, null: false,
        description: "Back-catalog lock: only patrons who were already supporting at release time qualify"
      field :tiers, [ PatreonTierType ], null: false,
        description: "The qualifying tiers (tier_list mode)"
    end
  end
end
