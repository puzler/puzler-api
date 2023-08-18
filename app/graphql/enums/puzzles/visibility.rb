# frozen_string_literal: true

module Enums
  module Puzzles
    class Visibility < BaseEnum
      description 'Enum for the visibility of a puzzle'

      generate_from_rails_enum Puzzle.visibilities
    end
  end
end
