class CreateRatings < ActiveRecord::Migration[7.2]
  def change
    create_table :ratings do |t|
      t.references :puzzle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :stars
      t.integer :difficulty_vote

      t.timestamps
    end

    add_index :ratings, [ :puzzle_id, :user_id ], unique: true
  end
end
