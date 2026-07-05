class PuzzleVersion < ApplicationRecord
  belongs_to :puzzle

  validates :version_number, presence: true, uniqueness: { scope: :puzzle_id }
  validates :solution_code, length: { maximum: 255 }, allow_nil: true

  before_validation :assign_version_number, on: :create

  default_scope { order(:version_number) }

  # Default display name is "v1", "v2", ... unless the author named the version.
  def display_name
    label.presence || "v#{version_number}"
  end

  # Does `input` match this version's setter-defined solution code? Whitespace- and
  # case-insensitive so "R1 R2…" style codes are forgiving to type. Blank code or
  # blank input never matches (the puzzle only accepts in-app solves).
  def solution_code_matches?(input)
    return false if solution_code.blank? || input.blank?

    ActiveSupport::SecurityUtils.secure_compare(normalize_code(solution_code), normalize_code(input))
  end

  def published?
    puzzle.published_version_id == id
  end

  # Whether this version's definition has the Fog of War global enabled. Fog
  # gates per-cell hash exposure and forces the solution into SudokuPad links.
  def fog_enabled?
    definition.is_a?(Hash) && definition.dig("globals", "fog", "enabled") == true
  end

  private

  def normalize_code(str)
    str.to_s.gsub(/\s+/, "").upcase
  end

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
