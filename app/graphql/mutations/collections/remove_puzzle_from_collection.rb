module Mutations
  module Collections
    class RemovePuzzleFromCollection < Mutations::BaseMutation
      description "Remove a puzzle from a collection (the puzzle itself is untouched)"

      argument :collection_id, ID, required: true, description: "The collection"
      argument :puzzle_id, ID, required: true, description: "Puzzle to remove"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(collection_id:, puzzle_id:)
        require_auth!
        collection = current_user.collections.find_by(id: collection_id)
        raise GraphQL::ExecutionError, "Collection not found" unless collection

        collection.collection_puzzles.where(puzzle_id:).destroy_all
        { collection: collection.reload, errors: [] }
      end
    end
  end
end
