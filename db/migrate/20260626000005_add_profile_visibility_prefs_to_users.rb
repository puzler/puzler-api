class AddProfileVisibilityPrefsToUsers < ActiveRecord::Migration[8.1]
  # Owner-controlled visibility for the public profile page. Kept as scalar
  # columns (a fixed, known set of preferences) rather than folded into a JSON
  # blob, matching the project's normalized-storage convention.
  #
  # solve_history_visibility is a four-level escalating disclosure: hidden(0) <
  # count(1) < puzzles(2) < detailed(3). Defaults to "count" so the solve count
  # that is already public today stays public; the more personal sections default
  # off. The profile owner always sees everything regardless of these flags.
  def change
    add_column :users, :solve_history_visibility, :integer, null: false, default: 1
    add_column :users, :show_stats, :boolean, null: false, default: true
    add_column :users, :show_favorites, :boolean, null: false, default: false
    add_column :users, :show_subscriptions, :boolean, null: false, default: false
    add_column :users, :show_activity, :boolean, null: false, default: false
  end
end
