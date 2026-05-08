class Favorite < ApplicationRecord
  belongs_to :puzzle
  belongs_to :user

  validates :puzzle_id, uniqueness: { scope: :user_id, message: "already favorited by this user" }
end
