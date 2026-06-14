# frozen_string_literal: true

module Types
  module Enums
    # Access mode for a collection — generated from Collection's `visibility` enum.
    class CollectionVisibilityEnum < BaseEnum
      description "Who can see a collection: private, unlisted, public, the patron/subscriber tiers, or containers-only"
      generate_from_rails_enum Collection.visibilities
    end
  end
end
