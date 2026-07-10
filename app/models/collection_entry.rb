# One ordered slot in a collection. Today the entryable is a Puzzle or a
# StoryPage; the entry row itself stays a pure ordering record so future
# per-entry settings (release time, gating) apply uniformly to every type.
class CollectionEntry < ApplicationRecord
  belongs_to :collection
  belongs_to :entryable, polymorphic: true

  default_scope { order(:position) }

  scope :puzzles, -> { where(entryable_type: "Puzzle") }

  validates :entryable_id, uniqueness: { scope: [ :collection_id, :entryable_type ] }
end
