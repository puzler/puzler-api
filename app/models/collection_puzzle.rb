class CollectionPuzzle < ApplicationRecord
  belongs_to :collection
  belongs_to :puzzle

  default_scope { order(:position) }

  validates :puzzle_id, uniqueness: { scope: :collection_id }
end
