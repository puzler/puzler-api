# frozen_string_literal: true

module FPuzzle
  module Exporters
    module ExporterHelpers
      def parse_address(address)
        if address.is_a? Hash
          "R#{address[:row].round + 1}C#{address[:column].round + 1}"
        else
          "R#{address.row.round + 1}C#{address.column.round + 1}"
        end
      end

      def address_to_cell_list(address)
        row = address.row + 1
        column = address.column + 1

        minRow = row.floor
        maxRow = row.ceil
        minCol = column.floor
        maxCol = column.ceil

        [
          "R#{minRow}C#{minCol}",
          "R#{minRow}C#{maxCol}",
          "R#{maxRow}C#{minCol}",
          "R#{maxRow}C#{maxCol}"
        ].uniq
      end
    end
  end
end
