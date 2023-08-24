# frozen_string_literal: true

module Interfaces
  module Puzzles
    module CellConnector
      include BaseInterface
      implements Interfaces::Puzzles::MultiCell

      description 'A constraint that connects multiple cells'

      field :location,
            Types::Puzzles::Address,
            null: false,
            description: 'The Visual location of the constraint'

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
