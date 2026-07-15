class AddReleasedAtToPuzzlesAndCollections < ActiveRecord::Migration[8.0]
  def change
    # Lazy scheduled release, mirroring collection_entries.released_at: nil or
    # past = released; future = invisible to non-authors until the moment passes.
    add_column :puzzles, :released_at, :datetime
    add_index :puzzles, :released_at, where: "released_at IS NOT NULL"

    add_column :collections, :released_at, :datetime
    add_index :collections, :released_at, where: "released_at IS NOT NULL"
  end
end
