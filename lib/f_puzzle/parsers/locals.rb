# frozen_string_literal: true

module FPuzzle
  module Parsers
    class Locals
      class << self
        include ParserHelpers

        def parse(puzzle_data)
          {
            **single_cell_locals(puzzle_data),
            **multi_cell_locals(puzzle_data),
            **outside_grid_locals(puzzle_data),
            **line_locals(puzzle_data),
            thermometers: parse_thermos(puzzle_data[:thermometer]),
            arrows: parse_arrows(puzzle_data[:arrow]),
            clones: puzzle_data[:clone]&.map do |data|
              {
                cells: data[:cells].map { |add| parse_address(add) },
                clone_cells: [data[:clone_cells].map { |add| parse_address(add) }]
              }
            end
          }.compact_blank
        end

        private

        def parse_thermos(thermometers)
          thermometers&.each_with_object([]) do |thermo, list|
            bulb = parse_address(thermo[:lines].first.first)
            lines = thermo[:lines].map { |line| line.map { |add| parse_address(add) } }

            match = list.find { |check| check[:bulb] == bulb }
            if match
              match[:lines] += lines
            else
              list << { bulb:, lines: }
            end
          end
        end

        def parse_arrows(arrows)
          arrows&.map do |arrow|
            {
              cells: arrow[:cells].map { |add| parse_address(add) },
              lines: arrow[:lines].map { |line| line.map { |add| parse_address(add) } }
            }
          end
        end

        def single_cell_locals(puzzle_data)
          {
            # Not implemented on f-puzzles
            # row_index_cells_cells: [],
            # column_index_cells: [],
            odd_cells: parse_single_cell_locals(puzzle_data[:odd]),
            even_cells: parse_single_cell_locals(puzzle_data[:even]),
            min_cells: parse_single_cell_locals(puzzle_data[:minimum]),
            max_cells: parse_single_cell_locals(puzzle_data[:maximum])
          }
        end

        def parse_single_cell_locals(local_list)
          local_list&.map do |data|
            { cell: parse_address(data[:cell]) }
          end
        end

        def multi_cell_locals(puzzle_data)
          {
            difference_dots: parse_multi_cell_local_group(puzzle_data[:difference], { difference: :value }),
            ratio_dots: parse_multi_cell_local_group(puzzle_data[:ratio], { ratio: :value }),
            xv: parse_multi_cell_local_group(puzzle_data[:xv], { xv_type: :value }),
            quadruples: parse_multi_cell_local_group(puzzle_data[:quadruple], { values: :values }),
            killer_cages: parse_multi_cell_local_group(puzzle_data[:killercage], { value: :value }),
            extra_regions: parse_multi_cell_local_group(puzzle_data[:extraregion])
          }
        end

        def parse_multi_cell_local_group(local_group, key_map = {})
          local_group&.map do |data|
            element = { cells: data[:cells].map { |add| parse_address(add) } }

            key_map.each do |output_key, input_key|
              element[output_key] = data[input_key]
            end

            element.compact
          end
        end

        def outside_grid_locals(puzzle_data)
          {
            # Not implemented on f-puzzles
            # x_sums: [],
            # skyscrapers: [],
            little_killer_sums: puzzle_data[:littlekillersum]&.map do |data|
              parse_outside_grid_element(data).merge(
                direction: {
                  top: data[:direction].include?('U'),
                  left: data[:direction].include?('L')
                }
              )
            end,
            sandwich_sums: parse_outside_grid_elements(puzzle_data[:sandwichsum])
          }
        end

        def parse_outside_grid_elements(data)
          data&.map { |d| parse_outside_grid_element(d) }
        end

        def parse_outside_grid_element(data)
          {
            location: parse_address(data[:cell]),
            value: data[:value]&.to_i
          }.compact
        end

        def line_locals(puzzle_data)
          {
            # Not implemented on f-puzzles
            # dutch_whisper_lines: [],
            # region_sum_lines: [],
            palindrome_lines: parse_lines(puzzle_data[:palindrome]),
            renban_lines: parse_lines(puzzle_data[:renban]),
            german_whisper_lines: parse_lines(puzzle_data[:whispers]),
            between_lines: parse_lines(puzzle_data[:betweenline])
          }
        end
      end
    end
  end
end
