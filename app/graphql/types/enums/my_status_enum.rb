# frozen_string_literal: true

module Types
  module Enums
    # The current viewer's relationship to a puzzle, for archive filtering.
    class MyStatusEnum < BaseEnum
      description "Filter by the current viewer's relationship to the puzzle"
      value "SOLVED", value: "SOLVED", description: "Puzzles the viewer has solved"
      value "UNSOLVED", value: "UNSOLVED", description: "Puzzles the viewer has not solved"
      value "FAVORITED", value: "FAVORITED", description: "Puzzles the viewer has favorited"
    end
  end
end
