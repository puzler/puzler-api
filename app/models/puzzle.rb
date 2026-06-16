class Puzzle < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :folder, optional: true

  has_many :versions, class_name: "PuzzleVersion", dependent: :destroy
  belongs_to :published_version, class_name: "PuzzleVersion", optional: true

  has_many :collection_puzzles, dependent: :destroy
  has_many :collections, through: :collection_puzzles
  has_many :collection_solve_times, dependent: :destroy
  has_many :series_entries, as: :entryable, dependent: :destroy

  has_many :constraints, dependent: :destroy
  has_many :cosmetics, dependent: :destroy
  has_many :puzzle_plays, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :puzzle_tags, dependent: :destroy
  has_many :tags, through: :puzzle_tags
  has_many :access_grants, class_name: "PuzzleAccessGrant", dependent: :destroy
  has_many :granted_users, through: :access_grants, source: :user

  # Lifecycle (draft → published) and access mode (who can see it) are
  # independent axes. "private"/"public" collide with Ruby keywords, so the
  # enum methods are prefixed: visible_private?, visible_public!, etc.
  enum :status, { draft: 0, published: 1 }
  # `containers_only` (added 2026-06-14) is hidden from the archive but surfaced
  # inside the author's own collections/series; for direct access it behaves
  # exactly like `unlisted` (the share_token is the secret).
  enum :visibility,
    { private: 0, unlisted: 1, public: 2, patrons_only: 3, subscribers_only: 4,
      containers_only: 5 },
    prefix: :visible

  before_create :generate_share_token

  # Once a puzzle has this many community difficulty votes, its effective
  # difficulty switches from the author's value to the community average.
  DIFFICULTY_VOTE_CUTOFF = 4

  validates :title, presence: true, length: { maximum: 100 }
  validates :author_difficulty, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  validates :grid_rows, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 25 }
  validates :grid_cols, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 25 }

  # The public archive lists only finished, public puzzles. Unlisted/private and
  # the future patron/subscriber tiers are reachable by link/grant, not listing.
  scope :publicly_visible, -> { where(status: :published, visibility: :public) }
  # Published puzzles that may appear inside a container the viewer can see:
  # public ones plus the container-only tier. Used to list a collection's
  # puzzles to non-authors.
  scope :container_visible, -> { where(status: :published, visibility: [ :public, :containers_only ]) }
  scope :by_newest, -> { order(published_at: :desc) }
  scope :by_rating, -> { order(avg_rating: :desc) }
  scope :by_popularity, -> { order(solve_count: :desc) }

  # Single source of truth for "can this viewer open this puzzle?". A share_token
  # gates unlisted access (the token IS the secret); private needs an explicit
  # grant; the patron/subscriber tiers are defined but denied until built.
  def viewable_by?(user, share_token: nil)
    return true if user && (user.id == author_id || user.admin?)
    return false if draft?

    case visibility
    when "public" then true
    when "unlisted", "containers_only" then share_token.present? && share_token == self.share_token
    when "private" then user.present? && access_grants.exists?(user_id: user.id)
    else false # patrons_only / subscribers_only — stubbed
    end
  end

  # After this puzzle's rating/solve aggregates change, refresh the denormalized
  # aggregates on every container that includes it. Collections cascade to their
  # own containing series, so here we only need to recompute collections plus
  # any series this puzzle is entered into directly.
  def refresh_container_aggregates!
    collections.each(&:recompute_aggregates!)
    Series.joins(:series_entries)
          .where(series_entries: { entryable_type: "Puzzle", entryable_id: id })
          .distinct.each(&:recompute_aggregates!)
  end

  # Recompute the community difficulty average and vote count, then resolve the
  # effective difficulty: the community average once there are enough votes,
  # otherwise the author's chosen value (nil until one of those exists).
  def recompute_difficulty!
    votes = ratings.where.not(difficulty_vote: nil)
    count = votes.count
    community = votes.average(:difficulty_vote)&.round(2)
    effective = count >= DIFFICULTY_VOTE_CUTOFF ? community : author_difficulty
    update_columns(avg_difficulty: community, difficulty_vote_count: count, effective_difficulty: effective)
  end

  private

  # Unguessable URL key for share/solve links (mirrors the jti pattern on User).
  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(16)
  end
end
