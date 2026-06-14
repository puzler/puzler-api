# frozen_string_literal: true

module Types
  module Enums
    # Lifecycle status for a puzzle — generated from Puzzle's `status` enum.
    class PuzzleStatusEnum < BaseEnum
      description "Lifecycle status of a puzzle: draft or published"
      generate_from_rails_enum Puzzle.statuses
    end
  end
end
