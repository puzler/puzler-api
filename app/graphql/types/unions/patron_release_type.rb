# frozen_string_literal: true

module Types
  module Unions
    # An item in the patron releases feed: a gated puzzle or collection.
    class PatronReleaseType < BaseUnion
      description "A patron release: a patrons-only puzzle or collection"
      possible_types Types::Objects::PuzzleType, Types::Objects::CollectionType

      def self.resolve_type(object, _context)
        object.is_a?(Puzzle) ? Types::Objects::PuzzleType : Types::Objects::CollectionType
      end
    end
  end
end
