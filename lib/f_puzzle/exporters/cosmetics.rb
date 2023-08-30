# frozen_string_literal: true

module FPuzzle
  module Exporters
    class Cosmetics
      class << self
        include ExporterHelpers

        def parse(puzzle)
          {
            cage: parse_cages(puzzle.cosmetics.cages),
            circle: parse_shapes(puzzle.cosmetics.circles),
            rectangle: parse_shapes(puzzle.cosmetics.rectangles),
            line: [
              *parse_lines(puzzle.cosmetics.lines),
              *parse_local_lines(puzzle.local_constraints)
            ],
            text: [
              *parse_text(puzzle.cosmetics.text),
              *parse_local_texts(puzzle.local_constraints)
            ]
          }.compact_blank
        end

        private

        def parse_cages(cages)
          cages&.map do |cage|
            {
              cells: cage.cells.map { |add| parse_address(add) },
              outlineC: ColorHelper.rgba_to_string(cage.cage_color),
              fontC: ColorHelper.rgba_to_string(cage.text_color),
              value: cage.text
            }
          end
        end

        def parse_shapes(shapes)
          shapes&.map do |shape|
            {
              cells: address_to_cell_list(shape.address),
              angle: shape.angle,
              baseC: ColorHelper.rgba_to_string(shape.fill_color),
              outlineC: ColorHelper.rgba_to_string(shape.outline_color),
              fontC: ColorHelper.rgba_to_string(shape.text_color),
              height: shape.height,
              width: shape.width,
              value: shape.text
            }
          end
        end

        def parse_lines(lines)
          lines&.map do |line|
            {
              lines: [line.points.map { |add| parse_address(add) }],
              width: line.width,
              outlineC: ColorHelper.rgba_to_string(line.color)
            }
          end || []
        end

        def parse_text(texts)
          texts&.map do |text|
            {
              cells: address_to_cell_list(text.address),
              angle: text.angle,
              fontC: ColorHelper.rgba_to_string(text.font_color),
              size: text.size,
              value: text.text
            }
          end || []
        end

        def parse_local_lines(locals)
          [
            *local_line_group(locals.renban_lines, LINE_STYLES[:renban]),
            *local_line_group(locals.german_whisper_lines, LINE_STYLES[:german_whisper]),
            *local_line_group(locals.dutch_whisper_lines, LINE_STYLES[:dutch_whisper]),
            *local_line_group(locals.region_sum_lines, LINE_STYLES[:region_sum])
          ].compact_blank
        end

        def local_line_group(lines, style)
          lines&.map do |line|
            {
              lines: [line.points.map { |add| parse_address(add) }],
              **style
            }
          end || []
        end

        LINE_STYLES = {
          renban: {
            outlineC: ColorHelper.rgba_to_string({ red: 240, green: 103, blue: 240, opacity: 1 }),
            width: 0.4
          },
          german_whisper: {
            outlineC: ColorHelper.rgba_to_string({ red: 103, green: 240, blue: 103, opacity: 1 }),
            width: 0.3
          },
          dutch_whisper: {
            outlineC: ColorHelper.rgba_to_string({ red: 255, green: 111, blue: 0, opacity: 1 }),
            width: 0.3
          },
          region_sum: {
            outlineC: ColorHelper.rgba_to_string({ red: 0, green: 200, blue: 255, opacity: 1 }),
            width: 0.25
          }
        }.freeze

        def parse_local_texts(locals)
          [
            *local_text_group(locals.x_sums, TEXT_STYLES[:x_sum]),
            *local_text_group(locals.skyscrapers, TEXT_STYLES[:skyscraper])
          ].compact_blank
        end

        def local_text_group(texts, style)
          texts&.map do |text|
            {
              cells: [parse_address(text.location)],
              value: text.value.to_s,
              **style
            }
          end || []
        end

        TEXT_STYLES = {
          x_sum: { fontC: ColorHelper.rgba_to_string({ red: 0, blue: 0, green: 0, opacity: 1 }), size: 0.9 },
          skyscraper: { fontC: ColorHelper.rgba_to_string({ red: 0, blue: 0, green: 0, opacity: 1 }), size: 0.9 }
        }.freeze
      end
    end
  end
end
