# frozen_string_literal: true

module InputObjects
  module Puzzles
    class NumberOutsideGridInput < BaseInputObject
      description 'Input for an element that has a number outside the grid'

      argument :location, AddressInput, required: true, description: 'The location of the clue'
      argument :value, String, required: true, description: 'The value of the clue'
    end
  end
end
