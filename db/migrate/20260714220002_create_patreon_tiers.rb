class CreatePatreonTiers < ActiveRecord::Migration[8.0]
  def change
    create_table :patreon_tiers do |t|
      t.references :patreon_campaign, null: false, foreign_key: true
      t.string :patreon_id, null: false
      t.string :title, null: false
      t.integer :amount_cents, null: false, default: 0
      t.boolean :published, null: false, default: true
      # Soft delete: tiers that vanish from the Patreon API are discarded, not
      # destroyed — patron gates reference them and the min-tier amount fallback
      # needs their recorded price.
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :patreon_tiers, [ :patreon_campaign_id, :patreon_id ], unique: true
  end
end
