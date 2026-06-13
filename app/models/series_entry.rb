class SeriesEntry < ApplicationRecord
  belongs_to :series
  # An entry points at either a Puzzle or a Collection.
  belongs_to :entryable, polymorphic: true

  default_scope { order(:position) }

  validates :entryable_id, uniqueness: { scope: [ :series_id, :entryable_type ],
    message: "is already in this series" }
end
