# One solver's single timed attempt at a competition collection. The deadline
# is frozen at start (started_at + the collection's limit at that moment), so
# later config edits can't move a live run's goalposts. Score columns stay nil
# until finalized_at is set. Login-only: fairness needs an attributable entrant.
class CreateCompetitionRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :competition_runs do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :deadline, null: false
      t.datetime :finished_at
      t.datetime :finalized_at
      t.integer :base_points
      t.integer :penalty_points
      t.integer :bonus_points
      t.integer :total_points
      t.integer :correct_count
      t.integer :time_used_seconds

      t.timestamps
    end

    add_index :competition_runs, [ :collection_id, :user_id ], unique: true
  end
end
