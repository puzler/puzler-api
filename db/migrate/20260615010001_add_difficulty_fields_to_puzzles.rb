class AddDifficultyFieldsToPuzzles < ActiveRecord::Migration[8.1]
  # New difficulty model: the setter picks author_difficulty (1-5); solvers vote
  # difficulty (1-5). Until a puzzle has DIFFICULTY_VOTE_CUTOFF community votes,
  # its effective_difficulty is the author's value; after that it's the community
  # average (avg_difficulty, now on a 1-5 scale). effective_difficulty is the
  # denormalized value the archive sorts/filters on.
  def change
    add_column :puzzles, :author_difficulty, :integer
    add_column :puzzles, :difficulty_vote_count, :integer, default: 0, null: false
    add_column :puzzles, :effective_difficulty, :float
    add_index :puzzles, :effective_difficulty
  end
end
