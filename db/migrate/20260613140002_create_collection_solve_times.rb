class CreateCollectionSolveTimes < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_solve_times do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :puzzle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :seconds, null: false

      t.timestamps
    end

    # One best time per solver per puzzle in a collection.
    add_index :collection_solve_times, [ :collection_id, :puzzle_id, :user_id ], unique: true,
      name: "index_collection_solve_times_unique"
  end
end
