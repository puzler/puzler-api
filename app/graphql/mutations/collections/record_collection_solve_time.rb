module Mutations
  module Collections
    class RecordCollectionSolveTime < Mutations::BaseMutation
      description "Record a solver's time for a puzzle within a timed collection (best time kept)"

      argument :collection_id, ID, required: true, description: "The collection"
      argument :puzzle_id, ID, required: true, description: "The solved puzzle"
      argument :seconds, Integer, required: true, description: "Elapsed solve time in seconds"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :recorded, Boolean, null: false, description: "Whether a time was recorded"

      def resolve(collection_id:, puzzle_id:, seconds:)
        require_auth!
        collection = Collection.find_by(id: collection_id)
        return deny unless collection&.viewable_by?(current_user)
        return deny unless collection.puzzle_entries.exists?(entryable_id: puzzle_id)
        return { recorded: false, errors: [ "Invalid time" ] } if seconds.to_i <= 0

        # find_by, not find: the membership check above doesn't survive a
        # concurrent puzzle deletion, and that race shouldn't 500.
        puzzle = Puzzle.find_by(id: puzzle_id)
        return deny unless puzzle

        CollectionSolveTime.record_best(collection:, puzzle:, user: current_user, seconds:)
        { recorded: true, errors: [] }
      end

      private

      def deny
        { recorded: false, errors: [ "Collection or puzzle not found" ] }
      end
    end
  end
end
