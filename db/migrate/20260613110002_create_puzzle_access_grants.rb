class CreatePuzzleAccessGrants < ActiveRecord::Migration[8.0]
  def change
    create_table :puzzle_access_grants do |t|
      t.references :puzzle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :granted_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :puzzle_access_grants, [ :puzzle_id, :user_id ], unique: true
  end
end
