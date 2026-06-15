# frozen_string_literal: true

module Types
  module Enums
    # Outcome of a "Check Solution" request. Deliberately coarse — it never
    # reveals WHICH cells are wrong, so it can't be used to brute-force the grid.
    class CheckResultEnum < BaseEnum
      description "Result of checking an in-progress board against the solution"

      value "SOLVED", "The board is complete and matches the solution"
      value "CORRECT_SO_FAR", "Incomplete, but every filled cell is correct"
      value "INCORRECT", "At least one filled cell is wrong"
    end
  end
end
