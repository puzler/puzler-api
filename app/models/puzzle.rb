class Puzzle < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :folder, optional: true

  has_many :versions, class_name: "PuzzleVersion", dependent: :destroy
  belongs_to :published_version, class_name: "PuzzleVersion", optional: true

  has_many :collection_entries, as: :entryable, dependent: :destroy
  has_many :collections, through: :collection_entries
  has_many :collection_solve_times, dependent: :destroy
  has_many :series_entries, as: :entryable, dependent: :destroy

  has_many :puzzle_plays, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :puzzle_tags, dependent: :destroy
  has_many :tags, through: :puzzle_tags
  has_many :access_grants, class_name: "PuzzleAccessGrant", dependent: :destroy
  has_many :granted_users, through: :access_grants, source: :user

  # Rich page description HTML + embedded images (shared with Collection and
  # StoryPage via the concern).
  include RichDescription

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

  include ShareTokenable

  # Once a puzzle has this many community difficulty votes, its effective
  # difficulty switches from the author's value to the community average.
  DIFFICULTY_VOTE_CUTOFF = 4

  validates :title, presence: true, length: { maximum: 100 }
  validates :author_difficulty, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  # Matches the frontend's GRID_MAX (app: utils/puzzleJson.ts) — 48 covers the
  # known gattai shapes (Samurai 21, Sumo 33, Shogun 21×45) with headroom.
  GRID_MAX = 48

  validates :grid_rows, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: GRID_MAX }
  validates :grid_cols, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: GRID_MAX }

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

  # Whether comments are gated to confirmed solvers. The per-puzzle override
  # wins when set; otherwise we inherit the author's account default.
  def comments_require_solve?
    comments_require_solve_override.nil? ? author.comments_require_solve_default : comments_require_solve_override
  end

  # Has this user successfully completed this puzzle? Used for the comment gate
  # and the "solved" badge on comments.
  def solver?(user)
    user.present? && puzzle_plays.completed.exists?(user_id: user.id)
  end

  # Actor-aware solver check: a guest's completed play (keyed by guest_token)
  # counts too, so off-site/guest solves gate the same UI as logged-in solves.
  def solved_by?(actor)
    return false unless actor
    return solver?(actor.user) if actor.user?

    puzzle_plays.completed.exists?(guest_token: actor.guest_token)
  end

  # Is this actor the puzzle's author? Authors can play their own puzzle but never
  # count as a solver (no is_solved, no solve_count, no rating). Guests are never
  # the author.
  def authored_by?(actor)
    actor&.user? && actor.user_id == author_id
  end

  # Record a completed solve for `actor`, the single chokepoint every solve path
  # funnels through (in-app board submit and off-site solution code). No-op for the
  # author. Idempotent per actor: solve_count is bumped only the first time this
  # actor completes the puzzle. Records against the actor's own play (the one their
  # StartPlay created, or a fresh one for a solo guest / off-site solver). Returns
  # :author, :already, or :recorded.
  def record_solve!(actor, cell_state: nil, time_elapsed_seconds: nil)
    return :author if authored_by?(actor)
    return :already if solved_by?(actor)

    play = puzzle_plays.find_or_initialize_by(actor.owner_attrs)
    play.is_solved = true
    play.completed_at = Time.current
    play.started_at ||= Time.current
    play.cell_state = cell_state unless cell_state.nil?
    play.time_elapsed_seconds = time_elapsed_seconds unless time_elapsed_seconds.nil?
    play.save!

    increment!(:solve_count)
    refresh_container_aggregates!
    :recorded
  end

  # (Re)build the cached SudokuPad short links from the published version, via the
  # backend converter. Stores the solution-less link always, and the
  # solution-embedded link only when the author opts in — except fog puzzles,
  # which always get one (SudokuPad needs the solution to clear fog). Best-effort:
  # a non-square/unsupported puzzle or a createlink failure leaves the column blank
  # (LinkBuilder falls back to the long ?puzzleid= URL on a shortener failure).
  def refresh_sudokupad_links!
    version = published_version
    unless version
      update_columns(sudokupad_url: nil, sudokupad_solution_url: nil)
      return
    end

    plain = Sudokupad::LinkBuilder.build(
      definition: version.definition, include_solution: false, fallback_author: author.display_name
    )
    solution_link =
      if author.include_solution_in_sudokupad_export || version.fog_enabled?
        Sudokupad::LinkBuilder.build(
          definition: version.definition, solution: version.solution,
          include_solution: true, fallback_author: author.display_name
        )
      end
    update_columns(sudokupad_url: plain&.dig(:short_url), sudokupad_solution_url: solution_link&.dig(:short_url))
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
end
