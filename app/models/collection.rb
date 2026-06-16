class Collection < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :folder, optional: true

  has_many :collection_puzzles, dependent: :destroy
  has_many :puzzles, through: :collection_puzzles
  has_many :collection_solve_times, dependent: :destroy
  has_many :series_entries, as: :entryable, dependent: :destroy

  # Mirrors Puzzle's access model. "private"/"public" collide with Ruby keywords,
  # so visibility methods are prefixed (visible_public?, etc.). `mode` governs
  # ordering only — timing/competition is a separate setting added later.
  # `containers_only` (added 2026-06-14) is hidden from the archive but surfaced
  # inside the author's own series; for direct access it behaves like `unlisted`.
  enum :visibility,
    { private: 0, unlisted: 1, public: 2, patrons_only: 3, subscribers_only: 4,
      containers_only: 5 },
    prefix: :visible
  enum :mode, { unordered: 0, sequence: 1 }

  before_create :generate_share_token

  validates :title, presence: true, length: { maximum: 100 }

  scope :publicly_visible, -> { visible_public }
  scope :by_rating, -> { order(avg_rating: :desc) }
  scope :by_popularity, -> { order(solve_count: :desc) }

  # Refresh the denormalized rating/solve aggregates from member puzzles:
  # average of members' star ratings and the sum of their solve counts. Also
  # cascades to any series this collection belongs to, since their aggregates
  # roll up these same puzzles.
  def recompute_aggregates!
    update_columns(
      avg_rating: puzzles.where.not(avg_rating: nil).average(:avg_rating)&.round(2),
      solve_count: puzzles.sum(:solve_count)
    )
    containing_series.each(&:recompute_aggregates!)
  end

  # Series that include this collection as an entry.
  def containing_series
    Series.joins(:series_entries)
          .where(series_entries: { entryable_type: "Collection", entryable_id: id })
          .distinct
  end

  # Can this viewer open the collection? Author/admin always; otherwise by
  # visibility. Private is author-only (no per-user grants for collections yet);
  # the patron/subscriber tiers are stubbed.
  def viewable_by?(user, share_token: nil)
    return true if user && (user.id == author_id || user.admin?)

    case visibility
    when "public" then true
    when "unlisted", "containers_only" then share_token.present? && share_token == self.share_token
    else false
    end
  end

  private

  # Unguessable URL key for share/series links (mirrors Puzzle#generate_share_token).
  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(16)
  end
end
