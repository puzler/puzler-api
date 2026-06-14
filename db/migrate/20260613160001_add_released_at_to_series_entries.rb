class AddReleasedAtToSeriesEntries < ActiveRecord::Migration[8.0]
  def change
    # NULL means released immediately (on creation). A future timestamp keeps
    # the entry hidden from non-authors until that moment.
    add_column :series_entries, :released_at, :datetime
    add_index :series_entries, :released_at
  end
end
