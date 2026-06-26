class AddGuestTokenToPuzzlePlays < ActiveRecord::Migration[8.1]
  # A guest-hosted collaborative play is owned by the host's opaque guest token
  # (client-generated, localStorage) instead of a user. These rows are transient —
  # pruned once the session empties. `user_id` (and its resume index) stays for
  # logged-in owners.
  def change
    add_column :puzzle_plays, :guest_token, :string
    add_index :puzzle_plays, :guest_token
    add_index :puzzle_plays, [ :puzzle_id, :guest_token ],
      where: "is_solved = false", name: "index_puzzle_plays_active_by_guest"
  end
end
