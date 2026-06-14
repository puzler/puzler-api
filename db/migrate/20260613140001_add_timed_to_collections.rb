class AddTimedToCollections < ActiveRecord::Migration[8.0]
  def change
    # Competition flag — when set, solvers are timed and a leaderboard is shown.
    # Kept as its own normalized column (filterable), separate from `mode`.
    add_column :collections, :timed, :boolean, null: false, default: false
  end
end
