class CreatePuzzleTags < ActiveRecord::Migration[7.2]
  def change
    create_table :puzzle_tags do |t|
      t.references :puzzle, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :puzzle_tags, [ :puzzle_id, :tag_id ], unique: true
  end
end
