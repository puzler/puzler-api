# frozen_string_literal: true

module Interfaces
  module Puzzles
    module NumberOutsideGrid
      include BaseInterface

      description 'An element with a number outside the grid'

      field :location, Types::Puzzles::Address, null: false, description: 'Location of the value'
      field :value, String, null: false, description: 'Value of the clue'
    end
  end
end
