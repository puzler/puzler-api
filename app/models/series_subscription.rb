class SeriesSubscription < ApplicationRecord
  belongs_to :series
  belongs_to :user

  validates :series_id, uniqueness: { scope: :user_id, message: "already subscribed by this user" }
end
