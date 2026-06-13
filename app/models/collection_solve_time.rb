class CollectionSolveTime < ApplicationRecord
  belongs_to :collection
  belongs_to :puzzle
  belongs_to :user

  validates :seconds, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: [ :collection_id, :puzzle_id ] }

  # Record a solver's time for a puzzle in a collection, keeping their best.
  def self.record_best(collection:, puzzle:, user:, seconds:)
    existing = find_by(collection:, puzzle:, user:)
    return existing if existing && existing.seconds <= seconds

    (existing || new(collection:, puzzle:, user:)).tap { |r| r.update!(seconds:) }
  end
end
