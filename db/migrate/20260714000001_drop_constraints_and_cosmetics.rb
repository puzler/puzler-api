class DropConstraintsAndCosmetics < ActiveRecord::Migration[8.0]
  # These tables are from the abandoned normalized-storage design; puzzles
  # persist all constraints/cosmetics inside the version's JSON definition.
  # Nothing has written to them since, but guard against surprises in prod.
  def up
    %w[constraints cosmetics].each do |table|
      count = select_value("SELECT COUNT(*) FROM #{table}").to_i
      raise "Refusing to drop #{table}: #{count} rows exist" if count.positive?
    end

    drop_table :constraints
    drop_table :cosmetics
  end

  def down
    create_table :constraints do |t|
      t.string :constraint_type, null: false
      t.jsonb :data, default: {}, null: false
      t.integer :display_order, default: 0, null: false
      t.references :puzzle, null: false, foreign_key: true
      t.timestamps
      t.index [ :puzzle_id, :constraint_type ]
    end

    create_table :cosmetics do |t|
      t.integer :cosmetic_type, default: 0, null: false
      t.jsonb :data, default: {}, null: false
      t.integer :display_order, default: 0, null: false
      t.jsonb :position, default: {}, null: false
      t.references :puzzle, null: false, foreign_key: true
      t.jsonb :style, default: {}, null: false
      t.timestamps
    end
  end
end
