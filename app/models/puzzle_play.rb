class PuzzlePlay < ApplicationRecord
  belongs_to :puzzle
  belongs_to :user, optional: true
  has_many :participants, class_name: "PuzzlePlayParticipant", dependent: :destroy
  has_many :share_tokens, class_name: "PuzzlePlayShareToken", dependent: :destroy

  validates :puzzle, presence: true

  scope :completed, -> { where(is_solved: true) }
  scope :in_progress, -> { where(is_solved: false) }

  # Who may read/sync/save this play: the owner, or a collaborator who joined via
  # a share token.
  def accessible_by?(user)
    return false unless user
    user_id == user.id || participants.exists?(user_id: user.id)
  end
end
