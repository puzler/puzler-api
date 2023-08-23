# frozen_string_literal: true

module FPuzzle
  module Parsers
    class Cosmetics
      class << self
        include ParserHelpers

        def parse(puzzle_data, cell_background_colors: nil)
          {
            cages: puzzle_data[:cage]&.each_with_object([]) do |cage_data, cages|
              next if cage_data[:value]&.starts_with? 'msgcorrect:'

              cages << parse_cage(cage_data, cosmetic: true)
            end,
            circles: parse_shapes(puzzle_data[:circle]),
            rectangles: parse_shapes(puzzle_data[:rectangle]),
            lines: parse_lines(puzzle_data[:line], cosmetic: true),
            text: parse_texts(puzzle_data[:text]),
            cell_background_colors:
          }.compact_blank
        end

        private

        def parse_shapes(shapes_data)
          shapes_data&.map do |data|
            {
              address: center_point_of_addresses(data[:cells]),
              angle: data[:angle],
              fill_color: ColorHelper.rgba_from_string(data[:base_c]),
              height: data[:height],
              outline_color: ColorHelper.rgba_from_string(data[:outline_c]),
              text: data[:value],
              text_color: ColorHelper.rgba_from_string(data[:font_c]),
              width: data[:width]
            }.compact
          end
        end

        def parse_texts(texts_data)
          texts_data&.map do |data|
            {
              address: center_point_of_addresses(data[:cells]),
              angle: data[:angle],
              font_color: ColorHelper.rgba_from_string(data[:font_c]),
              size: data[:size],
              text: data[:value]
            }.compact
          end
        end
      end
    end
  end
end
