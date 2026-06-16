# frozen_string_literal: true

module Types
  module Enums
    # Setter experience tier — generated from User's `setter_tier` enum.
    class SetterTierEnum < BaseEnum
      description "Setter experience tier: new, rising, or experienced"
      generate_from_rails_enum User.setter_tiers
    end
  end
end
