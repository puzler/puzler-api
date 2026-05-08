class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, :jwt_authenticatable,
         omniauth_providers: %i[google_oauth2 patreon],
         jwt_revocation_strategy: self

  enum :role, { user: 0, admin: 1 }

  has_many :oauth_identities, class_name: "UserOauthIdentity", dependent: :destroy
  has_many :puzzles, foreign_key: :author_id, dependent: :destroy, inverse_of: :author
  has_many :puzzle_plays, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_puzzles, through: :favorites, source: :puzzle

  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only letters, numbers, and underscores" },
                       length: { minimum: 3, maximum: 30 }
end
