class AddPuzzlePreferencesToUsers < ActiveRecord::Migration[8.1]
  # Per-user puzzle defaults, kept as scalar columns per the normalized-storage
  # convention (alongside the profile-visibility prefs).
  #
  # include_solution_in_sudokupad_export: governs whether a solution-embedded
  #   SudokuPad link is created for the author's published puzzles AND their own
  #   editor export. Defaults on (current behavior).
  #
  # comments_require_solve_default: the author's default for "only confirmed
  #   solvers can comment", overridable per puzzle. Defaults off (open comments).
  def change
    add_column :users, :include_solution_in_sudokupad_export, :boolean, null: false, default: true
    add_column :users, :comments_require_solve_default, :boolean, null: false, default: false
  end
end
