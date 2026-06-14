class CreatePuzzleVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :puzzle_versions do |t|
      t.references :puzzle, null: false, foreign_key: true
      t.integer :version_number, null: false
      t.string :label
      t.jsonb :definition, null: false, default: {}
      t.jsonb :solution, null: false, default: {}
      t.string :solution_hash
      t.string :constraint_types, array: true, null: false, default: []

      t.timestamps
    end

    add_index :puzzle_versions, [ :puzzle_id, :version_number ], unique: true
    add_index :puzzle_versions, :constraint_types, using: :gin
  end
end
