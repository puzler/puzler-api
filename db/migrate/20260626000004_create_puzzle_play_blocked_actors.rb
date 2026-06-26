class CreatePuzzlePlayBlockedActors < ActiveRecord::Migration[8.1]
  # Identities (user or guest) the host kicked AND barred from rejoining a
  # still-active multi-use-link session. Exactly one of user_id / guest_token is set.
  def change
    create_table :puzzle_play_blocked_actors do |t|
      t.references :puzzle_play, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :guest_token

      t.timestamps
    end

    add_index :puzzle_play_blocked_actors, [ :puzzle_play_id, :user_id ],
      unique: true, where: "user_id IS NOT NULL", name: "index_pp_blocked_on_play_and_user"
    add_index :puzzle_play_blocked_actors, [ :puzzle_play_id, :guest_token ],
      unique: true, where: "guest_token IS NOT NULL", name: "index_pp_blocked_on_play_and_guest"
  end
end
