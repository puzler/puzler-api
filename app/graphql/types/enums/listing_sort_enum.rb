# frozen_string_literal: true

module Types
  module Enums
    # Sort order for a listing of puzzles, collections, or series.
    class ListingSortEnum < BaseEnum
      description "Sort order for a listing"
      value "ALPHABETICAL", value: "ALPHABETICAL", description: "By title, A to Z"
      value "RECENT", value: "RECENT", description: "Most recently created first"
      value "RATING", value: "RATING", description: "Highest average rating first"
      value "SOLVES", value: "SOLVES", description: "Most solved first"
    end
  end
end
