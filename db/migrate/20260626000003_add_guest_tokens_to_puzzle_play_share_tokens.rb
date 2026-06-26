class AddGuestTokensToPuzzlePlayShareTokens < ActiveRecord::Migration[8.1]
  # A share token can be created by a guest host and consumed by a guest joiner,
  # so created_by/consumed_by become optional with guest-token counterparts.
  def change
    change_column_null :puzzle_play_share_tokens, :created_by_id, true
    add_column :puzzle_play_share_tokens, :created_by_guest_token, :string
    add_column :puzzle_play_share_tokens, :consumed_by_guest_token, :string
  end
end
