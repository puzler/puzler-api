# frozen_string_literal: true

module FPuzzle
  module Parsers
    module ParserHelpers
      def parse_address(address_str)
        match = /^R(?<row>-{0,1}\d+)C(?<column>-{0,1}\d+)$/.match(address_str)
        return if match.nil?

        match.named_captures.each_with_object({}) do |(key, value), address|
          address[key.to_sym] = value.to_i - 1
        end
      end

      def center_point_of_addresses(raw_addresses)
        addresses = raw_addresses.map { |str| parse_address(str) }

        grouped = addresses.each_with_object({ rows: [], columns: [] }) do |address, out|
          out[:rows] << address[:row]
          out[:columns] << address[:column]
        end

        {
          row: grouped[:rows].minmax.sum / 2.0,
          column: grouped[:columns].minmax.sum / 2.0
        }
      end

      def parse_cage(cage_data, cosmetic: false)
        cage = {
          cells: cage_data[:cells].map { |address| parse_address(address) }
        }

        if cosmetic
          cage.merge!(
            cage_color: ColorHelper.rgba_from_string(cage_data[:outline_c]),
            text_color: ColorHelper.rgba_from_string(cage_data[:font_c])
          )
          cage[:text] = cage_data[:value] if cage_data[:value].present?
        elsif cage_data[:value].present?
          cage.merge!(value: cage_data[:value].to_i)
        end

        cage
      end

      def parse_lines(lines_data, cosmetic: false)
        lines_data&.map do |data|
          parse_line(data, cosmetic:)
        end&.flatten
      end

      def parse_line(line_data, cosmetic: false)
        return [] if cosmetic && line_data[:is_new_constraint]

        line_data[:lines]&.map do |line_addresses|
          line = { points: line_addresses.map { |address| parse_address(address) } }

          if cosmetic
            line.merge!(
              width: line_data[:width],
              color: ColorHelper.rgba_from_string(line_data[:outline_c])
            )
          end

          line
        end
      end
    end
  end
end
