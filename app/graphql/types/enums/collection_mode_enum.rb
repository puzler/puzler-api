# frozen_string_literal: true

module Types
  module Enums
    # Ordering mode for a collection — generated from Collection's `mode` enum.
    class CollectionModeEnum < BaseEnum
      description "Ordering mode for a collection: unordered or sequence"
      generate_from_rails_enum Collection.modes
    end
  end
end
