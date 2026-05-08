class CreatePuzzlePlays < ActiveRecord::Migration[7.2]
  def change
    create_table :puzzle_plays do |t|
      t.references :puzzle, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.jsonb :cell_state, null: false, default: {}
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :time_elapsed_seconds, default: 0
      t.boolean :is_solved, null: false, default: false

      t.timestamps
    end
  end
end
