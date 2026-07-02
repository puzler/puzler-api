module Mutations
  module Collections
    class RemovePuzzleFromCollection < Mutations::BaseMutation
      description "Remove a puzzle from a collection (the puzzle itself is untouched)"

      argument :collection_id, ID, required: true, description: "The collection"
      argument :puzzle_id, ID, required: true, description: "Puzzle to remove"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(collection_id:, puzzle_id:)
        collection = require_owned!(:collections, "Collection", id: collection_id)

        removed = collection.collection_puzzles.where(puzzle_id:).destroy_all
        collection.recompute_aggregates! if removed.any?
        { collection: collection.reload, errors: [] }
      end
    end
  end
end
