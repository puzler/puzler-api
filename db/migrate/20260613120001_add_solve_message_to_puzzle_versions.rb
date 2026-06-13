class AddSolveMessageToPuzzleVersions < ActiveRecord::Migration[8.0]
  def change
    # Custom "you solved it" message (a puzzle-hunt clue, etc.). Author-only and
    # never served in the play definition — revealed only on a correct solve.
    add_column :puzzle_versions, :solve_message, :text
  end
end
