class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, :jwt_authenticatable,
         omniauth_providers: %i[google_oauth2 patreon],
         jwt_revocation_strategy: self

  enum :role, { user: 0, admin: 1 }

  has_one_attached :avatar

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

  before_update :mark_password_set_and_rotate_jti, if: :will_save_change_to_encrypted_password?

  def generate_jwt
    Warden::JWTAuth::UserEncoder.new.call(self, :user, nil).first
  end

  # Uploaded avatar wins; the avatar_url column holds an OAuth profile image
  # captured at first sign-in and acts as the fallback.
  def resolved_avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(
        avatar, host: ENV.fetch("API_URL", "http://localhost:3000")
      )
    else
      avatar_url
    end
  end

  private

  # Any password change (set, change, or reset) marks the password usable for
  # login and revokes all outstanding JWTs. Callers that need to keep the
  # current session alive must issue a fresh token after saving.
  def mark_password_set_and_rotate_jti
    self.password_set = true
    self.jti = SecureRandom.uuid
  end
end
