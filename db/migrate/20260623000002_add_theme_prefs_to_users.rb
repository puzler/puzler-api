class AddThemePrefsToUsers < ActiveRecord::Migration[8.1]
  # The user's theme SELECTION + the custom-styles gate. Kept as scalar columns (not in the
  # player_settings blob) because themes are a separate concern. `active_theme_id` is a
  # built-in preset id ("classic"/"light"/"dark") or a user_themes.uid; resolved with a
  # "classic" fallback by the frontend if it dangles. `enable_custom_styles` off reverts the
  # whole grid (background + constraint styling) to defaults while chrome keeps the theme.
  def change
    add_column :users, :active_theme_id, :string, null: false, default: "classic"
    add_column :users, :enable_custom_styles, :boolean, null: false, default: true
  end
end
