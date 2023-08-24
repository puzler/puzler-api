# frozen_string_literal: true

module Interfaces
  module Puzzles
    module MultiCell
      include BaseInterface

      description 'An element that references Multiple Cells'

      field :cells,
            [Types::Puzzles::Address],
            null: false,
            description: 'Cells included in the constraint'
    end
  end
end
