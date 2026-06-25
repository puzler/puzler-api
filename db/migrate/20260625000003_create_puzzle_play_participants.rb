class CreatePuzzlePlayParticipants < ActiveRecord::Migration[8.1]
  # Co-solvers of a shared play session (the owner is `puzzle_plays.user_id`;
  # these are the people who joined via a share token). Mirrors puzzle_access_grants.
  def change
    create_table :puzzle_play_participants do |t|
      t.references :puzzle_play, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :added_via_token, null: true,
        foreign_key: { to_table: :puzzle_play_share_tokens }

      t.timestamps
    end

    add_index :puzzle_play_participants, [ :puzzle_play_id, :user_id ], unique: true
  end
end
