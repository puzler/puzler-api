class CreatePatreonMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :patreon_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :patreon_campaign, null: false, foreign_key: true
      t.string :patreon_member_id
      t.integer :patron_status, null: false, default: 0
      t.integer :entitled_amount_cents, null: false, default: 0
      # Patreon tier ids (strings) the member is currently entitled to. A set of
      # external ids consumed as a whole — schemaless sub-data, not an entity.
      t.string :entitled_patreon_tier_ids, array: true, null: false, default: []
      # Patreon's start of the member's current pledge chain. Resets when a
      # lapsed patron re-joins, so first_active_at (ours, set once on first
      # sighting of active_patron) backs the back-catalog check for returners.
      t.datetime :pledge_relationship_start
      t.datetime :first_active_at
      t.datetime :synced_at, null: false
      t.integer :source, null: false, default: 0

      t.timestamps
    end

    add_index :patreon_memberships, [ :user_id, :patreon_campaign_id ], unique: true
    add_index :patreon_memberships, [ :patreon_campaign_id, :patreon_member_id ]
  end
end
