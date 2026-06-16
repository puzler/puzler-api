class Rating < ApplicationRecord
  belongs_to :puzzle
  belongs_to :user

  validates :stars, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  # difficulty_vote is a 1-5 community difficulty assessment (1 = gentlest).
  validates :difficulty_vote, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  validates :puzzle_id, uniqueness: { scope: :user_id, message: "already rated by this user" }
end
