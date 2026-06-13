class CreateCollectionPuzzles < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_puzzles do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :puzzle, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :collection_puzzles, [ :collection_id, :puzzle_id ], unique: true
    add_index :collection_puzzles, [ :collection_id, :position ]
  end
end
