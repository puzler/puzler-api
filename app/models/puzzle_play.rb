class PuzzlePlay < ApplicationRecord
  belongs_to :puzzle
  belongs_to :user, optional: true
  has_many :participants, class_name: "PuzzlePlayParticipant", dependent: :destroy
  has_many :share_tokens, class_name: "PuzzlePlayShareToken", dependent: :destroy
  has_many :blocked_actors, class_name: "PuzzlePlayBlockedActor", dependent: :destroy

  validates :puzzle, presence: true

  scope :completed, -> { where(is_solved: true) }
  scope :in_progress, -> { where(is_solved: false) }
  # Transient guest-hosted rows (owned by a guest token, no user) the pruner reaps.
  scope :guest_hosted, -> { where(user_id: nil).where.not(guest_token: nil) }

  def guest_hosted?
    user_id.nil? && guest_token.present?
  end

  # All authorization is by Actor (a user or a guest) — see app/models/actor.rb.
  def owned_by?(actor)
    return false unless actor
    actor.user? ? user_id == actor.user_id : guest_token.present? && guest_token == actor.guest_token
  end

  def participant_for?(actor)
    return false unless actor
    actor.user? ? participants.exists?(user_id: actor.user_id) : participants.exists?(guest_token: actor.guest_token)
  end

  # Who may read/sync/save this play: the owner or an accepted collaborator.
  def accessible_by?(actor)
    return false unless actor
    owned_by?(actor) || participant_for?(actor)
  end

  def blocked?(actor)
    return false unless actor
    actor.user? ? blocked_actors.exists?(user_id: actor.user_id) : blocked_actors.exists?(guest_token: actor.guest_token)
  end
end
