class CreateUserThemes < ActiveRecord::Migration[8.1]
  # A user's saved appearance/constraint themes — a first-class entity (not a blob inside
  # player_settings). `appearance` and `constraints` are sparse override maps owned by the
  # frontend (utils/theme.ts defines their shape); the API stores and returns them verbatim.
  #
  # `uid` is a client-generated stable id: the frontend creates themes offline (local-first,
  # like the color palette) and uses `uid` as the identity everywhere, so the same id survives
  # the anonymous → synced transition. It is what the GraphQL `id` exposes; the bigint pk stays
  # internal. `users.active_theme_id` (added in the next migration) references a uid or a
  # built-in preset id ("classic"/"light"/"dark").
  def change
    create_table :user_themes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :uid, null: false
      t.string :name, null: false
      t.string :base_preset_id, null: false, default: "classic"
      t.integer :schema_version, null: false, default: 1
      t.jsonb :appearance, null: false, default: {}
      t.jsonb :constraints, null: false, default: {}
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :user_themes, [ :user_id, :position ]
    add_index :user_themes, [ :user_id, :uid ], unique: true
  end
end
