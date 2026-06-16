class RescaleDifficultyVotes < ActiveRecord::Migration[8.1]
  # difficulty_vote moves from the old 4-level enum (easy:0..expert:3) to a plain
  # 1-5 integer. Map existing votes 0..3 -> 1..4 so historical data stays valid;
  # puzzle difficulty aggregates are recomputed by the difficulty:backfill task.
  def up
    execute "UPDATE ratings SET difficulty_vote = difficulty_vote + 1 WHERE difficulty_vote IS NOT NULL"
  end

  def down
    execute "UPDATE ratings SET difficulty_vote = difficulty_vote - 1 WHERE difficulty_vote IS NOT NULL"
  end
end
