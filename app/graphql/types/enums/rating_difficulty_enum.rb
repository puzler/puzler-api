# frozen_string_literal: true

module Types
  module Enums
    # A solver's difficulty assessment — generated from Rating's `difficulty_vote` enum.
    class RatingDifficultyEnum < BaseEnum
      description "A solver's difficulty vote: easy, medium, hard, or expert"
      generate_from_rails_enum Rating.difficulty_votes
    end
  end
end
