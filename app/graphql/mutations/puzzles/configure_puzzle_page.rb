module Mutations
  module Puzzles
    # Save the per-puzzle comment-gate override the editor collects alongside
    # publishing. (SudokuPad links are now built server-side on publish, so they
    # are no longer passed in here.)
    class ConfigurePuzzlePage < Mutations::BaseMutation
      description "Save a puzzle's publish-page settings (comment gating)"

      argument :comments_require_solve_override, Boolean, required: false,
        description: "Override for 'only confirmed solvers can comment' (pass null to inherit the account default)"
      argument :puzzle_id, ID, required: true, description: "ID of the puzzle"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The updated puzzle"

      def resolve(puzzle_id:, comments_require_solve_override: :unset)
        puzzle = require_owned!(:puzzles, "Puzzle", id: puzzle_id)

        attrs = {}
        attrs[:comments_require_solve_override] = comments_require_solve_override unless comments_require_solve_override == :unset

        if puzzle.update(attrs)
          { puzzle:, errors: [] }
        else
          { puzzle: nil, errors: puzzle.errors.full_messages }
        end
      end
    end
  end
end
