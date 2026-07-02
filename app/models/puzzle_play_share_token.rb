class PuzzlePlayShareToken < ApplicationRecord
  belongs_to :puzzle_play
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :consumed_by, class_name: "User", optional: true

  before_create :generate_token

  # Still usable to join: not revoked, and not yet consumed (by a user or a guest).
  # Multi-use tokens never set a consumer (the participants table tracks joiners),
  # so they stay shareable until revoked; single-use tokens lock on first consume.
  scope :shareable, -> { where(revoked_at: nil, consumed_by_id: nil, consumed_by_guest_token: nil) }

  def shareable?
    revoked_at.nil? && consumed_by_id.nil? && consumed_by_guest_token.nil?
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
