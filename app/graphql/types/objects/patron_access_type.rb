module Types
  module Objects
    # The viewer's resolved standing against a patron-gated item — everything
    # the teaser lock panel needs. Resolved from a plain hash.
    class PatronAccessType < BaseObject
      description "The current viewer's access to a patrons-only puzzle or collection"

      field :campaign_title, String, null: true, description: "The gating creator's campaign name"
      field :campaign_url, String, null: true,
        description: "The creator's patreon.com page (the become-a-patron link)"
      field :has_access, Boolean, null: false, description: "Whether the viewer can open the item"
      field :locked_reason, Types::Enums::PatronLockReasonEnum, null: true,
        description: "Why the viewer is locked out; null when hasAccess"
      field :required_amount_cents, Integer, null: true,
        description: "The gate's effective minimum pledge, when one applies"
      field :required_tier_title, String, null: true,
        description: "The minimum tier's name, when the gate is tier-based"
    end
  end
end
