class PuzzlePlay < ApplicationRecord
  belongs_to :puzzle
  belongs_to :user, optional: true

  validates :puzzle, presence: true

  scope :completed, -> { where(is_solved: true) }
  scope :in_progress, -> { where(is_solved: false) }
end
