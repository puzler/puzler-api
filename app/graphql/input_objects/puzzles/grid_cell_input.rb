# frozen_string_literal: true

module InputObjects
  module Puzzles
    class GridCellInput < BaseInputObject
      description 'Input for a Grid Cell'

      argument :digit, Integer, required: false, description: 'The given digit for the cell'
      argument :given, Boolean, required: false, description: 'If the cell contains a given digit'
      argument :region, Integer, required: true, description: "The cell's region"
    end
  end
end
