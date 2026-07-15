class CreatePatreonCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :patreon_campaigns do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :patreon_id, null: false
      t.string :title
      t.string :url
      t.string :currency
      # active / token_stale keep the creator features on; disconnected / removed
      # demote the visibility allowlist but never touch existing gated content.
      t.integer :status, null: false, default: 0
      t.string :webhook_patreon_id
      t.text :webhook_secret
      t.datetime :webhook_paused_at
      t.datetime :campaign_synced_at
      t.datetime :members_synced_at
      # Creator's "show locked previews to non-patrons" toggle. Off = gated items
      # behave like private for non-qualifying viewers (no teasers anywhere).
      t.boolean :teasers_enabled, null: false, default: true

      t.timestamps
    end

    add_index :patreon_campaigns, :patreon_id, unique: true
  end
end
