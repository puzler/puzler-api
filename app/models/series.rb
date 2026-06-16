class Series < ApplicationRecord
  self.table_name = "series"

  belongs_to :author, class_name: "User"

  has_many :series_entries, dependent: :destroy
  has_many :series_subscriptions, dependent: :destroy
  has_many :subscribers, through: :series_subscriptions, source: :user

  # Mirrors Collection's access model. "private"/"public" collide with Ruby
  # keywords, so visibility methods are prefixed (visible_public?, etc.).
  # `containers_only` mirrors Puzzle/Collection for enum symmetry; it isn't
  # selectable for a series (a series isn't embedded in anything higher).
  enum :visibility,
    { private: 0, unlisted: 1, public: 2, patrons_only: 3, subscribers_only: 4,
      containers_only: 5 },
    prefix: :visible

  before_create :generate_share_token

  validates :title, presence: true, length: { maximum: 100 }

  scope :publicly_visible, -> { visible_public }
  scope :by_rating, -> { order(avg_rating: :desc) }
  scope :by_popularity, -> { order(solve_count: :desc) }

  # Refresh the denormalized rating/solve aggregates from member puzzles. A
  # series entry is either a puzzle (counts directly) or a collection (counts
  # via its member puzzles), so both paths are flattened before aggregating.
  def recompute_aggregates!
    puzzles = member_puzzles
    rated = puzzles.filter_map(&:avg_rating)
    update_columns(
      avg_rating: rated.any? ? (rated.sum / rated.size).round(2) : nil,
      solve_count: puzzles.sum(&:solve_count)
    )
  end

  # Distinct puzzles reachable from this series: those entered directly plus
  # those inside entered collections.
  def member_puzzles
    entries = series_entries.includes(:entryable)
    direct = entries.select { |e| e.entryable_type == "Puzzle" }.map(&:entryable)
    via_collections = entries.select { |e| e.entryable_type == "Collection" }
                             .flat_map { |e| e.entryable&.puzzles&.to_a || [] }
    (direct + via_collections).compact.uniq
  end

  # Can this viewer open the series? Author/admin always; otherwise by
  # visibility. Private is author-only; the patron/subscriber tiers are stubbed.
  def viewable_by?(user, share_token: nil)
    return true if user && (user.id == author_id || user.admin?)

    case visibility
    when "public" then true
    when "unlisted" then share_token.present? && share_token == self.share_token
    else false
    end
  end

  private

  # Unguessable URL key for share links (mirrors Collection#generate_share_token).
  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(16)
  end
end
