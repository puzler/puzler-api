# The solution has lived on puzzle_versions since the versioned-publish
# lifecycle; these puzzle-level copies were only written by the pre-version
# draft flow and silently diverged (empty for every version-published puzzle),
# which broke server-side grading. Grading now reads the published version.
class RemoveLegacySolutionFromPuzzles < ActiveRecord::Migration[8.1]
  def change
    remove_column :puzzles, :solution, :jsonb, default: {}, null: false
    remove_column :puzzles, :solution_hash, :string
  end
end
