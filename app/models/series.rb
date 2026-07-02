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

  include ShareTokenable

  validates :title, presence: true, length: { maximum: 100 }

  scope :publicly_visible, -> { visible_public }
  scope :by_rating, -> { order(avg_rating: :desc) }
  scope :by_popularity, -> { order(solve_count: :desc) }

  # Refresh the denormalized rating/solve aggregates from member puzzles. This
  # runs on every solve of a puzzle in the series, so it aggregates in SQL
  # rather than loading every member puzzle into memory.
  def recompute_aggregates!
    update_columns(
      avg_rating: member_puzzles.average(:avg_rating)&.round(2),
      solve_count: member_puzzles.sum(:solve_count)
    )
  end

  # Distinct puzzles reachable from this series: those entered directly plus
  # those inside entered collections. A relation (deduped by primary key), so
  # callers can aggregate or filter without materializing the whole set.
  def member_puzzles
    direct = series_entries.where(entryable_type: "Puzzle").select(:entryable_id)
    entered_collections = series_entries.where(entryable_type: "Collection").select(:entryable_id)
    via_collections = CollectionPuzzle.where(collection_id: entered_collections).select(:puzzle_id)
    Puzzle.where(id: direct).or(Puzzle.where(id: via_collections))
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
end
