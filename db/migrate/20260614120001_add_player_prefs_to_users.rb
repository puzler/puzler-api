class AddPlayerPrefsToUsers < ActiveRecord::Migration[8.0]
  # Per-user solving preferences for the player/solver page, persisted so they
  # follow the user across sessions and devices. Both are free-form JSON blobs
  # owned by the frontend (the player-settings store and the color-palette
  # store define their shapes); the API just stores and returns them verbatim.
  # `player_settings` holds the solver-settings toggles; `color_palette` holds
  # the user's customized cell-coloring palette (colors + pages).
  def change
    add_column :users, :player_settings, :jsonb, default: {}, null: false
    add_column :users, :color_palette, :jsonb, default: {}, null: false
  end
end
