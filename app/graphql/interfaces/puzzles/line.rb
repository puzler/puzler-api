# frozen_string_literal: true

module Interfaces
  module Puzzles
    module Line
      include BaseInterface

      description 'An element that makes up a line in the grid'

      field :points, [Types::Puzzles::Address], null: false, description: 'Cells along the line'
    end
  end
end
