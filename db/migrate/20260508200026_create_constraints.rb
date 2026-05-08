class CreateConstraints < ActiveRecord::Migration[7.2]
  def change
    create_table :constraints do |t|
      t.references :puzzle, null: false, foreign_key: true
      t.string :constraint_type, null: false
      t.jsonb :data, null: false, default: {}
      t.integer :display_order, null: false, default: 0

      t.timestamps
    end

    add_index :constraints, [ :puzzle_id, :constraint_type ]
  end
end
