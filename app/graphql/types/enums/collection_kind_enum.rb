# frozen_string_literal: true

module Types
  module Enums
    # What a collection is — generated from Collection's `kind` enum.
    class CollectionKindEnum < BaseEnum
      description "What a collection is: a plain list, a rich hunt, or a timed competition"
      generate_from_rails_enum Collection.kinds
    end
  end
end
