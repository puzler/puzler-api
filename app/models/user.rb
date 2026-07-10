class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, :jwt_authenticatable,
         omniauth_providers: %i[google_oauth2 patreon],
         jwt_revocation_strategy: self

  enum :role, { user: 0, admin: 1 }
  # Setter experience tier, derived from setter_score by recompute_setter_stats!.
  # Prefixed because `new` collides with the class method.
  enum :setter_tier, { new: 0, rising: 1, experienced: 2 }, prefix: :setter

  # How much of this user's solving activity their public profile reveals — an
  # escalating disclosure, each level less private than the last (see
  # SOLVE_HISTORY_LEVELS). Prefixed for readable predicate/scope names
  # (solve_history_hidden?, etc.).
  enum :solve_history_visibility, { hidden: 0, count: 1, puzzles: 2, detailed: 3 },
       prefix: :solve_history

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
  has_many :story_pages, foreign_key: :author_id, dependent: :destroy, inverse_of: :author
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
  has_many :user_themes, dependent: :destroy
  has_many :puzzle_play_participations, class_name: "PuzzlePlayParticipant", dependent: :destroy
  has_many :consumed_play_share_tokens, class_name: "PuzzlePlayShareToken",
    foreign_key: :consumed_by_id, dependent: :nullify, inverse_of: :consumed_by

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

  # When the author flips whether their SudokuPad links embed the solution,
  # rebuild the cached links on all their published puzzles to match.
  after_update :refresh_sudokupad_links, if: :saved_change_to_include_solution_in_sudokupad_export?

  def generate_jwt
    Warden::JWTAuth::UserEncoder.new.call(self, :user, nil).first
  end

  # The solve-history disclosure levels in order of increasing openness. Used to
  # express the four-level gate ("is this user disclosing at least <level>?") in
  # one place so the GraphQL resolvers stay declarative.
  SOLVE_HISTORY_LEVELS = %w[hidden count puzzles detailed].freeze

  # True when this user's solve-history disclosure is at or above `level`.
  def solve_history_at_least?(level)
    SOLVE_HISTORY_LEVELS.index(solve_history_visibility) >= SOLVE_HISTORY_LEVELS.index(level.to_s)
  end

  # Recency decay applied per puzzle (newest weighted 1, each older × this) when
  # blending an author's ratings into their setter score.
  SETTER_RECENCY_DECAY = 0.85

  # Recompute the denormalized setter score + tier from the author's published
  # public puzzles: blend volume (saturating, log scale) with a recency-weighted
  # average star rating (newest puzzles count most). The tier gates on BOTH
  # enough puzzles AND a high enough recency-weighted rating. Stored so the
  # archive can filter/sort by setter experience cheaply.
  def recompute_setter_stats!
    ratings = puzzles.publicly_visible.order(published_at: :desc).pluck(:avg_rating)
    count = ratings.size

    weighted_rating = recency_weighted_average(ratings)
    volume = Math.log10(count + 1)
    score = (volume * (weighted_rating / 5.0) * 5).round(3)

    tier =
      if count >= 5 && weighted_rating >= 4.0 then :experienced
      elsif count >= 2 && weighted_rating >= 3.0 then :rising
      else :new
      end

    update_columns(setter_score: score, setter_tier: User.setter_tiers[tier])
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

  # Enqueue a link rebuild per published puzzle (async — each makes a createlink
  # call). Draft puzzles have no published version, so nothing to refresh.
  def refresh_sudokupad_links
    puzzles.where(status: :published).find_each { |puzzle| SudokupadLinkRefreshJob.perform_later(puzzle.id) }
  end

  # Geometric recency-weighted mean of the present ratings (input is newest-first;
  # nil ratings are skipped but still consume a recency slot so an unrated recent
  # puzzle doesn't inflate older ones). Returns 0.0 when nothing is rated.
  def recency_weighted_average(ratings)
    num = 0.0
    den = 0.0
    ratings.each_with_index do |rating, index|
      next if rating.nil?

      weight = SETTER_RECENCY_DECAY**index
      num += rating * weight
      den += weight
    end
    den.zero? ? 0.0 : num / den
  end

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
