class SeriesEntry < ApplicationRecord
  belongs_to :series
  # An entry points at either a Puzzle or a Collection.
  belongs_to :entryable, polymorphic: true

  default_scope { order(:position) }

  # Released now: either no schedule set, or the scheduled moment has passed.
  scope :released, -> { where("released_at IS NULL OR released_at <= ?", Time.current) }

  validates :entryable_id, uniqueness: { scope: [ :series_id, :entryable_type ],
    message: "is already in this series" }

  def released?
    released_at.nil? || released_at <= Time.current
  end

  # When this entry became (or becomes) visible — used to order the feed.
  def effective_release_at
    released_at || created_at
  end

  # May the puzzle/collection this entry points at be shown to a non-author
  # viewing the series? True for public targets and for the container-only tier
  # (which exists precisely to surface inside a series).
  def viewable_in_container?
    case entryable_type
    when "Puzzle" then entryable&.published? && (entryable&.visible_public? || entryable&.visible_containers_only?)
    when "Collection" then entryable&.visible_public? || entryable&.visible_containers_only?
    else false
    end
  end
end
