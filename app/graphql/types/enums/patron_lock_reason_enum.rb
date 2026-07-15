# frozen_string_literal: true

module Types
  module Enums
    # Why patron-gated content is locked for the viewer — drives the teaser
    # panel's call to action.
    class PatronLockReasonEnum < BaseEnum
      description "Why the viewer can't open this patron-gated content"
      # Values are symbols to match PatronAccess#locked_reason.
      value "NOT_LINKED", value: :not_linked,
        description: "The viewer has no Patreon account linked (or is logged out)"
      value "NOT_PATRON", value: :not_patron,
        description: "Linked, but not an active patron of this creator"
      value "INSUFFICIENT_TIER", value: :insufficient_tier,
        description: "An active patron, but below this release's gate"
      value "JOINED_AFTER_RELEASE", value: :joined_after_release,
        description: "This release was reserved for patrons at the time it came out"
      value "DECLINED", value: :declined,
        description: "The viewer's Patreon payment is currently declined"
      value "CREATOR_UNAVAILABLE", value: :creator_unavailable,
        description: "The creator's Patreon campaign is no longer available"
    end
  end
end
