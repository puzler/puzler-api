module Mutations
  module Collections
    class ReorderCollectionPuzzles < Mutations::BaseMutation
      description "Set the order of puzzles in a collection"

      argument :collection_id, ID, required: true, description: "The collection"
      argument :ordered_puzzle_ids, [ ID ], required: true,
        description: "Puzzle IDs in the desired order; sets each position by its index"

      field :collection, Types::Objects::CollectionType, null: true, description: "The reordered collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(collection_id:, ordered_puzzle_ids:)
        require_auth!
        collection = current_user.collections.find_by(id: collection_id)
        raise GraphQL::ExecutionError, "Collection not found" unless collection

        ordered_puzzle_ids.each_with_index do |puzzle_id, index|
          collection.collection_puzzles.where(puzzle_id:).update_all(position: index)
        end

        { collection: collection.reload, errors: [] }
      end
    end
  end
end
