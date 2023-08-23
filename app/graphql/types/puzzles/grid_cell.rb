# frozen_string_literal: true

module Types
  module Puzzles
    class GridCell < BaseType
      description 'A Cell in a puzzle grid'

      field :digit, Integer, null: true, description: 'The digit inside the cell'
      field :given, Boolean, null: true, description: 'If the cell contains a given digit'
      field :region, Integer, null: false, description: 'The region the cell belongs to'
    end
  end
end
