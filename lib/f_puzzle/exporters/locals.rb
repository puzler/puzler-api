# frozen_string_literal: true

module FPuzzle
  module Exporters
    class Locals
      class << self
        include ExporterHelpers

        def parse(puzzle)
          {
            **parse_single_cell_locals(puzzle.local_constraints),
            **parse_multi_cell_locals(puzzle.local_constraints),
            **parse_outside_grid_locals(puzzle.local_constraints),
            **parse_line_locals(puzzle.local_constraints),
            thermometer: parse_thermos(puzzle.local_constraints.thermometers),
            arrow: parse_arrows(puzzle.local_constraints.arrows),
            clone: parse_clones(puzzle.local_constraints.clones)
          }
        end

        private

        def parse_thermos(thermometers)
          thermometers&.map do |thermo|
            {
              lines: thermo.lines.map { |line| line.map { |add| parse_address(add) } }
            }
          end
        end

        def parse_arrows(arrows)
          arrows&.map do |arrow|
            {
              cells: arrow.cells.map { |add| parse_address(add) },
              lines: arrow.lines.map { |line| line.map { |add| parse_address(add) } }
            }
          end
        end

        def parse_line_locals(locals)
          {
            palindrome: line_list(locals.palindrome_lines),
            renban: line_list(locals.renban_lines),
            whispers: line_list(locals.german_whisper_lines),
            betweenline: line_list(locals.between_lines),
            dutchwhisper: line_list(locals.dutch_whisper_lines),
            regionsum: line_list(locals.region_sum_lines)
          }
        end

        def parse_clones(clones)
          list = []

          clones&.each do |clone|
            clone.clone_cells.each do |cloned_cells|
              list.push(
                cells: clone.cells.map { |add| parse_address(add) },
                cloneCells: cloned_cells.map { |add| parse_address(add) }
              )
            end
          end

          return if list.blank?

          list
        end

        def line_list(lines)
          lines&.map do |line|
            {
              lines: [line.points.map { |address| parse_address(address) }]
            }
          end
        end

        def parse_outside_grid_locals(locals)
          {
            sandwichsum: outside_grid(locals.sandwich_sums),
            skyscraper: outside_grid(locals.skyscrapers),
            xsum: outside_grid(locals.x_sums),
            littlekillersum: locals.little_killer_sums&.map do |killer|
              {
                cell: parse_address(killer.location),
                value: killer.value&.to_s,
                direction: "#{killer.direction.top ? 'U' : 'D'}#{killer.direction.left ? 'L' : 'R'}"
              }
            end
          }
        end

        def outside_grid(items)
          items&.map do |item|
            {
              cell: parse_address(item.location),
              value: item.value&.to_s
            }
          end
        end

        def parse_single_cell_locals(locals)
          {
            odd: single_cell(locals.odd_cells),
            even: single_cell(locals.even_cells),
            minimum: single_cell(locals.min_cells),
            maximum: single_cell(locals.max_cells),
            rowindex: single_cell(locals.row_index_cells),
            columnindex: single_cell(locals.column_index_cells)
          }
        end

        def single_cell(items, **kw_map)
          items&.map do |item|
            {
              cell: parse_address(item.cell),
              **process_kw_map(kw_map, item)
            }
          end
        end

        def parse_multi_cell_locals(locals)
          {
            difference: parse_cell_connector(locals.difference_dots, value: :difference),
            ratio: parse_cell_connector(locals.ratio_dots, value: :ratio),
            xv: parse_cell_connector(locals.xv, value: :xv_type),
            quadruple: parse_cell_connector(locals.quadruples, values: :values),
            killercage: parse_multi_cell(locals.killer_cages, value: :value),
            extraregion: parse_multi_cell(locals.extra_regions)
          }
        end

        def parse_multi_cell(list, **kw_map)
          list&.map do |item|
            {
              cells: item.cells.map { |add| parse_address(add) },
              **process_kw_map(kw_map, item)
            }
          end
        end

        def parse_cell_connector(list, **kw_map)
          list&.map do |item|
            rows, columns = item.cells.each_with_object([[], []]) do |address, lists|
              lists[0] << address.row
              lists[1] << address.column
            end

            {
              cells: rows.uniq.map do |row|
                columns.uniq.map { |column| parse_address({ row:, column: }) }
              end.flat,
              **process_kw_map(kw_map, item)
            }
          end
        end

        def process_kw_map(kw_map, item)
          kw_map.transform_values do |input_key|
            val = item[input_key]
            if val.is_a? Array
              val
            else
              val.to_s
            end
          end
        end
      end
    end
  end
end
