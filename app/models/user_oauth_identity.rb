class UserOauthIdentity < ApplicationRecord
  belongs_to :user

  PROVIDERS = %w[google patreon].freeze

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }
end
