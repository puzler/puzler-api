module Types
  module Objects
    # A user's per-account puzzle defaults. Resolved from the User itself; only
    # exposed to the owner (see UserType#puzzle_preferences).
    class PuzzlePreferencesType < BaseObject
      description "A user's per-account puzzle defaults"

      field :comments_require_solve_default, Boolean, null: false,
        description: "Default for 'only confirmed solvers can comment' on the user's puzzles"
      field :include_solution_in_sudokupad_export, Boolean, null: false,
        description: "Whether the solution is included in the user's SudokuPad links/exports"
    end
  end
end
