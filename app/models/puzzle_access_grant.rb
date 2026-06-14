class PuzzleAccessGrant < ApplicationRecord
  belongs_to :puzzle
  belongs_to :user
  belongs_to :granted_by, class_name: "User"

  validates :user_id, uniqueness: { scope: :puzzle_id }
end
