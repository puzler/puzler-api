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

      def location
        groups = object['cells'].each_with_object({ rows: [], columns: [] }) do |cell, list|
          list[:rows] << cell['row']
          list[:columns] << cell['column']
        end

        {
          row: groups[:rows].minmax.sum / 2.0,
          column: groups[:columns].minmax.sum / 2.0
        }
      end
    end
  end
end
