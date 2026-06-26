class PuzzlePlayParticipant < ApplicationRecord
  belongs_to :puzzle_play
  belongs_to :user, optional: true
  belongs_to :added_via_token, class_name: "PuzzlePlayShareToken", optional: true

  validates :user_id, uniqueness: { scope: :puzzle_play_id }, allow_nil: true
  validates :guest_token, uniqueness: { scope: :puzzle_play_id }, allow_nil: true
  validate :exactly_one_identity

  private

  def exactly_one_identity
    errors.add(:base, "must have exactly one identity (user or guest)") unless user_id.present? ^ guest_token.present?
  end
end
