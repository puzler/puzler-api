# Scheduled release for collection entries (ports the series_entries pattern):
# nil means released on creation; a future timestamp keeps the entry invisible
# to non-authors until the moment passes. Opt-in per entry, like every hunt
# mechanic.
class AddReleasedAtToCollectionEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :collection_entries, :released_at, :datetime
    add_index :collection_entries, :released_at, where: "released_at IS NOT NULL"
  end
end
