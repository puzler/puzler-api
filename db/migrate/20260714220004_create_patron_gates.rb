class CreatePatronGates < ActiveRecord::Migration[8.0]
  def change
    create_table :patron_gates do |t|
      t.string :gateable_type, null: false
      t.bigint :gateable_id, null: false
      t.integer :mode, null: false, default: 0
      t.references :min_tier, foreign_key: { to_table: :patreon_tiers }
      t.integer :min_amount_cents
      # Back-catalog lock: only patrons whose membership predates the item's
      # release moment qualify. New patrons never unlock it.
      t.boolean :patrons_since_release, null: false, default: false

      t.timestamps
    end

    add_index :patron_gates, [ :gateable_type, :gateable_id ], unique: true

    # tier_list mode: one row per selected tier (any number of tiers).
    create_table :patron_gate_tiers do |t|
      t.references :patron_gate, null: false, foreign_key: true
      t.references :patreon_tier, null: false, foreign_key: true

      t.timestamps
    end

    add_index :patron_gate_tiers, [ :patron_gate_id, :patreon_tier_id ], unique: true
  end
end
