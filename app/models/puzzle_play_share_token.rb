class PuzzlePlayShareToken < ApplicationRecord
  belongs_to :puzzle_play
  belongs_to :created_by, class_name: "User"
  belongs_to :consumed_by, class_name: "User", optional: true

  before_create :generate_token

  # Still usable to join: not revoked, and not yet consumed. Multi-use tokens
  # never set consumed_by (the participants table tracks joiners), so they stay
  # shareable until revoked; single-use tokens lock on first consumption.
  scope :shareable, -> { where(revoked_at: nil, consumed_by_id: nil) }

  def shareable?
    revoked_at.nil? && consumed_by_id.nil?
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(8)
  end
end
