# frozen_string_literal: true

module Types
  module Enums
    # Access mode for a puzzle — generated from Puzzle's `visibility` enum so the
    # GraphQL values stay in lockstep with the model.
    class PuzzleVisibilityEnum < BaseEnum
      description "Who can see a puzzle: private, unlisted, public, the patron/subscriber tiers, or containers-only"
      generate_from_rails_enum Puzzle.visibilities
    end
  end
end
