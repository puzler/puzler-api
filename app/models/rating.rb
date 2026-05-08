class Rating < ApplicationRecord
  belongs_to :puzzle
  belongs_to :user

  enum :difficulty_vote, { easy: 0, medium: 1, hard: 2, expert: 3 }

  validates :stars, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  validates :puzzle_id, uniqueness: { scope: :user_id, message: "already rated by this user" }
end
