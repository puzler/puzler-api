# Collections are growing beyond flat puzzle lists (story pages interleave with
# puzzles for narrative "hunt" collections), so the join becomes a polymorphic
# entry list. In-place rename: no data is copied and row ids/positions survive.
class RenameCollectionPuzzlesToCollectionEntries < ActiveRecord::Migration[8.0]
  def change
    rename_table :collection_puzzles, :collection_entries
    rename_column :collection_entries, :puzzle_id, :entryable_id

    # The temporary default backfills existing rows; new rows must say their type.
    add_column :collection_entries, :entryable_type, :string, null: false, default: "Puzzle"
    change_column_default :collection_entries, :entryable_type, from: "Puzzle", to: nil

    # Polymorphic targets can't keep a real FK to puzzles.
    remove_foreign_key :collection_entries, :puzzles

    remove_index :collection_entries, column: [ :collection_id, :entryable_id ], unique: true
    remove_index :collection_entries, column: :entryable_id
    add_index :collection_entries, [ :collection_id, :entryable_type, :entryable_id ],
      unique: true, name: "index_collection_entries_unique"
    add_index :collection_entries, [ :entryable_type, :entryable_id ]
  end
end
