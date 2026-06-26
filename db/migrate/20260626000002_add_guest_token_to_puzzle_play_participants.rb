class AddGuestTokenToPuzzlePlayParticipants < ActiveRecord::Migration[8.1]
  # A participant is a user OR a guest (opaque token). Make user_id nullable and
  # add guest_token; a guest can't double-join one play.
  def change
    change_column_null :puzzle_play_participants, :user_id, true
    add_column :puzzle_play_participants, :guest_token, :string
    add_index :puzzle_play_participants, [ :puzzle_play_id, :guest_token ],
      unique: true, where: "guest_token IS NOT NULL",
      name: "index_pp_participants_on_play_and_guest"
  end
end
