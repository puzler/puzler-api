# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Globals
      class DiagonalsInput < BaseInputObject
        description 'Input for a Diagonals Global Constraint'
        argument :negative, Boolean, required: true, description: 'Top left to bottom right'
        argument :positive, Boolean, required: true, description: 'Bottom left to top right'
      end
    end
  end
end
