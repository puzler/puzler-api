module Mutations
  module Puzzles
    class SchedulePuzzleRelease < Mutations::BaseMutation
      description "Schedule (or clear) a puzzle's release moment. Until it passes, the puzzle " \
                  "is invisible to everyone but the author; it then appears everywhere " \
                  "automatically — no job runs, release is evaluated on read."

      argument :id, ID, required: true, description: "ID of the puzzle"
      argument :released_at, GraphQL::Types::ISO8601DateTime, required: false,
        description: "When the puzzle becomes available; null releases immediately"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The updated puzzle"

      def resolve(id:, released_at: nil)
        puzzle = require_owned!(:puzzles, "Puzzle", id:)

        if puzzle.update(released_at:)
          { puzzle:, errors: [] }
        else
          { puzzle: nil, errors: puzzle.errors.full_messages }
        end
      end
    end
  end
end
