# Competition authors choose whether solvers see each puzzle's point value
# (default yes — visible points let competitors strategize; hiding them keeps
# the weighting a secret).
class AddShowEntryPointsToCollections < ActiveRecord::Migration[8.0]
  def change
    add_column :collections, :show_entry_points, :boolean, default: true, null: false
  end
end
