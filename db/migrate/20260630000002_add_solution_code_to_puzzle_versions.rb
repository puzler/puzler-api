class AddSolutionCodeToPuzzleVersions < ActiveRecord::Migration[8.1]
  def change
    # Optional setter-defined code (e.g. "row 1 digits, then row 2") that lets a
    # solver who played off-site (SudokuPad, print, etc.) claim a solve. Blank
    # means the puzzle only accepts in-app board submissions.
    add_column :puzzle_versions, :solution_code, :string
  end
end
