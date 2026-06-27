module Types
  module InputObjects
    # Per-user puzzle defaults. Every field optional so a single toggle saves
    # without resending the rest (mirrors ProfileVisibilityInput).
    class PuzzlePreferencesInput < BaseInputObject
      description "Per-account puzzle defaults"

      argument :comments_require_solve_default, Boolean, required: false,
        description: "Default for 'only confirmed solvers can comment' on your puzzles"
      argument :include_solution_in_sudokupad_export, Boolean, required: false,
        description: "Include the solution in SudokuPad links for your published puzzles and your own exports"
    end
  end
end
