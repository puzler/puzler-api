class PuzzleVersion < ApplicationRecord
  belongs_to :puzzle

  validates :version_number, presence: true, uniqueness: { scope: :puzzle_id }

  before_validation :assign_version_number, on: :create

  default_scope { order(:version_number) }

  # Default display name is "v1", "v2", ... unless the author named the version.
  def display_name
    label.presence || "v#{version_number}"
  end

  def published?
    puzzle.published_version_id == id
  end

  private

  # Draws from the puzzle's monotonic counter so numbers are never reused, even
  # after older versions are deleted. with_lock guards concurrent saves.
  def assign_version_number
    return if version_number.present?

    puzzle.with_lock do
      self.version_number = puzzle.version_counter + 1
      puzzle.update_column(:version_counter, version_number)
    end
  end
end
