# Hunt mechanics, all opt-in per entry: a codeword gate (digest of the word a
# solver must enter), hidden bonus entries (invisible until their codeword is
# entered), and finale entries (unlock only when every other puzzle in the
# collection is solved). Defaults leave every existing collection fully open.
class AddGatesToCollectionEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :collection_entries, :codeword_digest, :string
    add_column :collection_entries, :hidden, :boolean, default: false, null: false
    add_column :collection_entries, :finale, :boolean, default: false, null: false

    # Which actors have opened which codeword gates. Mirrors the puzzle_plays
    # owner pattern: a row belongs to a user OR an opaque guest token.
    create_table :collection_entry_unlocks do |t|
      t.references :collection_entry, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :guest_token

      t.timestamps
    end

    add_index :collection_entry_unlocks, [ :collection_entry_id, :user_id ],
      unique: true, where: "user_id IS NOT NULL",
      name: "index_entry_unlocks_on_entry_and_user"
    add_index :collection_entry_unlocks, [ :collection_entry_id, :guest_token ],
      unique: true, where: "guest_token IS NOT NULL",
      name: "index_entry_unlocks_on_entry_and_guest"
  end
end
