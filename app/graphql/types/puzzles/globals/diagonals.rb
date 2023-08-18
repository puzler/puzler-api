# frozen_string_literal: true

module Types
  module Puzzles
    module Globals
      class Diagonals < BaseType
        description 'Diagonal Global Constraint Settings'
        field :negative, Boolean, null: false, description: 'Top left to bottom right'
        field :positive, Boolean, null: false, description: 'Bottom left to top right'
      end
    end
  end
end
