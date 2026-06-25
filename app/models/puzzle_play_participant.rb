class PuzzlePlayParticipant < ApplicationRecord
  belongs_to :puzzle_play
  belongs_to :user
  belongs_to :added_via_token, class_name: "PuzzlePlayShareToken", optional: true

  validates :user_id, uniqueness: { scope: :puzzle_play_id }
end
