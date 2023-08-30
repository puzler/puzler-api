# frozen_string_literal: true

module FPuzzle
  module Exporters
    class Grid
      class << self
        include ExporterHelpers

        def parse(puzzle)
          { grid: parse_grid(puzzle) }
        end

        private

        def parse_grid(puzzle)
          grid = puzzle.cells.map do |row_cells|
            row_cells.map do |cell|
              {
                region: cell.region,
                value: cell.digit,
                given: cell.given
              }
            end
          end

          puzzle.cosmetics.cell_background_colors&.each do |cell_color|
            apply_color(cell_color, grid)
          end
          apply_local_colors(puzzle.local_constraints, grid)

          grid
        end

        def apply_color(cell_color, grid)
          grid[cell_color.cell.row.round][cell_color.cell.column.round].merge!(
            c: ColorHelper.rgba_to_string(cell_color.colors.first),
            c_array: cell_color.colors.map { |rgba| ColorHelper.rgba_to_string(rgba) }
          )
        end

        def apply_local_colors(locals, grid)
          apply_colors_for(locals.row_index_cells, grid, LOCAL_TYPE_COLORS[:row_index])
          apply_colors_for(locals.column_index_cells, grid, LOCAL_TYPE_COLORS[:column_index])
        end

        def apply_colors_for(items, grid, color)
          items&.each do |item|
            cell = grid[item.cell.row][item.cell.column]
            if cell[:c].nil?
              cell.merge!(
                c: color,
                c_array: [color]
              )
            end
          end
        end

        LOCAL_TYPE_COLORS = {
          row_index: '#FFA0A0',
          column_index: '#60D060'
        }.freeze
      end
    end
  end
end
