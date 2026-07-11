# A solver's submission state for one puzzle within a run: one row per
# run+puzzle, upserted so the last submission is the one that counts. Graded on
# write (the verdict is stored but only revealed per the collection's policy);
# wrong_attempts counts every incorrect submission for the instant policy's
# per-attempt penalties.
class CreateCompetitionSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :competition_submissions do |t|
      t.references :competition_run, null: false, foreign_key: true
      t.references :puzzle, null: false, foreign_key: true
      t.boolean :correct, null: false
      t.jsonb :cell_state
      t.integer :wrong_attempts, default: 0, null: false
      t.datetime :submitted_at, null: false

      t.timestamps
    end

    add_index :competition_submissions, [ :competition_run_id, :puzzle_id ],
      unique: true, name: "index_competition_submissions_unique"
  end
end
