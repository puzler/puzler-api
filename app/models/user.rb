class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, :jwt_authenticatable,
         omniauth_providers: %i[google_oauth2 patreon],
         jwt_revocation_strategy: self

  enum :role, { user: 0, admin: 1 }

  # Standardized 256x256 avatar: square-cropped, EXIF stripped (libvips drops
  # metadata when transforming), served via the named variant below.
  AVATAR_VARIANT = { resize_to_fill: [ 256, 256 ] }.freeze

  has_one_attached :avatar do |attachable|
    attachable.variant :display, **AVATAR_VARIANT
  end

  has_many :oauth_identities, class_name: "UserOauthIdentity", dependent: :destroy
  has_many :puzzles, foreign_key: :author_id, dependent: :destroy, inverse_of: :author
  has_many :folders, foreign_key: :author_id, dependent: :destroy, inverse_of: :author
  has_many :collections, foreign_key: :author_id, dependent: :destroy, inverse_of: :author
  has_many :collection_solve_times, dependent: :destroy
  has_many :series, foreign_key: :author_id, dependent: :destroy, inverse_of: :author
  has_many :series_subscriptions, dependent: :destroy
  has_many :subscribed_series, through: :series_subscriptions, source: :series
  has_many :puzzle_plays, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_puzzles, through: :favorites, source: :puzzle
  has_many :puzzle_access_grants, dependent: :destroy
  has_many :accessible_puzzles, through: :puzzle_access_grants, source: :puzzle

  # username is the unique handle used in profile URLs, lookups, and access
  # grants — kept strict (letters/numbers/underscores).
  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only letters, numbers, and underscores" },
                       length: { minimum: 3, maximum: 30 }

  # display_name is the free-form, mutable, NON-unique name shown to others
  # (spaces and punctuation allowed). New records fall back to the username.
  normalizes :display_name, with: ->(value) { value&.strip }
  before_validation :default_display_name, on: :create
  validates :display_name, presence: true, length: { maximum: 50 }

  before_update :mark_password_set_and_rotate_jti, if: :will_save_change_to_encrypted_password?

  def generate_jwt
    Warden::JWTAuth::UserEncoder.new.call(self, :user, nil).first
  end

  # Uploaded avatar wins (served as the normalized :display variant); the
  # avatar_url column holds an OAuth profile image captured at first sign-in
  # and acts as the fallback.
  def resolved_avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_representation_url(
        avatar.variant(:display), host: ENV.fetch("API_URL", "http://localhost:3000")
      )
    else
      avatar_url
    end
  end

  private

  def default_display_name
    self.display_name = username if display_name.blank?
  end

  # Any password change (set, change, or reset) marks the password usable for
  # login and revokes all outstanding JWTs. Callers that need to keep the
  # current session alive must issue a fresh token after saving.
  def mark_password_set_and_rotate_jti
    self.password_set = true
    self.jti = SecureRandom.uuid
  end
end
