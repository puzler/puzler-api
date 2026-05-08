class CreatePuzzles < ActiveRecord::Migration[7.2]
  def change
    create_table :puzzles do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.integer :grid_rows, null: false, default: 9
      t.integer :grid_cols, null: false, default: 9
      t.jsonb :box_layout
      t.jsonb :given_digits, null: false, default: {}
      t.jsonb :solution, null: false, default: {}
      t.string :solution_hash
      t.jsonb :ruleset, null: false, default: {}
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.float :avg_difficulty
      t.float :avg_rating
      t.integer :solve_count, null: false, default: 0
      t.integer :favorite_count, null: false, default: 0

      # Patreon integration foundation
      t.string :patreon_campaign_id
      t.integer :patron_visibility, default: 0

      t.timestamps
    end

    add_index :puzzles, :status
    add_index :puzzles, :published_at
    add_index :puzzles, :solution_hash
  end
end
