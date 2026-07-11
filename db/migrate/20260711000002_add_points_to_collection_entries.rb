# Per-puzzle scoring weight for competition collections; dormant elsewhere.
class AddPointsToCollectionEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :collection_entries, :points, :integer, default: 10, null: false
  end
end
