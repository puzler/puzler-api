module Mutations
  module Collections
    class AddPuzzleToCollection < Mutations::BaseMutation
      description "Add one of your puzzles to the end of a collection"

      argument :collection_id, ID, required: true, description: "Target collection"
      argument :puzzle_id, ID, required: true, description: "Puzzle to add"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(collection_id:, puzzle_id:)
        collection = require_owned!(:collections, "Collection", id: collection_id)
        puzzle = require_owned!(:puzzles, "Puzzle", id: puzzle_id)

        unless collection.puzzle_entries.exists?(entryable_id: puzzle.id)
          # Position over ALL entries: puzzles and story pages share one sequence.
          next_position = (collection.entries.maximum(:position) || -1) + 1
          collection.entries.create!(entryable: puzzle, position: next_position)
          collection.recompute_aggregates!
        end

        { collection: collection.reload, errors: [] }
      end
    end
  end
end
