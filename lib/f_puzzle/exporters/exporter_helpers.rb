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

        min_row = row.floor
        max_row = row.ceil
        min_col = column.floor
        max_col = column.ceil

        [
          "R#{min_row}C#{min_col}",
          "R#{min_row}C#{max_col}",
          "R#{max_row}C#{min_col}",
          "R#{max_row}C#{max_col}"
        ].uniq
      end
    end
  end
end
