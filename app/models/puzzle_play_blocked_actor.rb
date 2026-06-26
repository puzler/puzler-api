class PuzzlePlayBlockedActor < ApplicationRecord
  belongs_to :puzzle_play
  belongs_to :user, optional: true

  validate :exactly_one_identity

  private

  def exactly_one_identity
    errors.add(:base, "must have exactly one identity (user or guest)") unless user_id.present? ^ guest_token.present?
  end
end
