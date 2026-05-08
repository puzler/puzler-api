class CreateCosmetics < ActiveRecord::Migration[7.2]
  def change
    create_table :cosmetics do |t|
      t.references :puzzle, null: false, foreign_key: true
      t.integer :cosmetic_type, null: false, default: 0
      t.jsonb :position, null: false, default: {}
      t.jsonb :style, null: false, default: {}
      t.jsonb :data, null: false, default: {}
      t.integer :display_order, null: false, default: 0

      t.timestamps
    end
  end
end
