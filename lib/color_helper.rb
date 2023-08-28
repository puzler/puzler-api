# frozen_string_literal: true

class ColorHelper
  class << self
    def rgba_from_string(string_color)
      return if string_color.nil?

      value_type, raw_values = raw_rgba_values(string_color)
      return unless raw_values

      {
        red: parse_raw_value(raw_values[:red], value_type),
        green: parse_raw_value(raw_values[:green], value_type),
        blue: parse_raw_value(raw_values[:blue], value_type),
        opacity: parse_raw_value(raw_values[:alpha], value_type, max: 1.0)
      }
    end

    private

    def parse_raw_value(value, value_type, max: 255.0)
      return max if value.nil?

      case value_type
      when :hex
        number = value.ljust(2, value).to_i(16)
        return (number / 255.0) * max
      when :number
        return value.to_f
      end

      nil
    end

    # rubocop:disable Layout/LineLength
    def regex
      {
        hex_no_alpha: /^#(?<red>[0-9a-fA-F]{2})(?<green>[0-9a-fA-F]{2})(?<blue>[0-9a-fA-F]{2})$/,
        hex_with_alpha: /^#(?<red>[0-9a-fA-F]{2})(?<green>[0-9a-fA-F]{2})(?<blue>[0-9a-fA-F]{2})(?<alpha>[0-9a-fA-F]{1,2})$/,
        short_hex_no_alpha: /^#(?<red>[0-9a-fA-F])(?<green>[0-9a-fA-F])(?<blue>[0-9a-fA-F])$/,
        short_hex_with_alpha: /^#(?<red>[0-9a-fA-F])(?<green>[0-9a-fA-F])(?<blue>[0-9a-fA-F])(?<alpha>[0-9a-fA-F])$/,
        rgb: /^rgb\((?<red>\d{1,3}(?>\.\d+){0,1})[\s,]*(?<green>\d{1,3}(?>\.\d+){0,1})[\s,]+(?<blue>\d{1,3}(?>\.\d+){0,1})\)$/,
        rgba: /^rgba\((?<red>\d{1,3}(?>\.\d+){0,1})[\s,]*(?<green>\d{1,3}(?>\.\d+){0,1})[\s,]+(?<blue>\d{1,3}(?>\.\d+){0,1})[\s,]+(?<alpha>1|0{0,1}\.\d+)\)$/
      }
    end
    # rubocop:enable Layout/LineLength

    def value_type_for_regex_type(regex_type)
      return :number if regex_type.to_s.starts_with?('rgb')

      :hex
    end

    def raw_rgba_values(string_color)
      regex.each do |regex_type, regx|
        match = regx.match string_color
        next if match.nil?

        return [
          value_type_for_regex_type(regex_type),
          match.named_captures.transform_keys(&:to_sym)
        ]
      end

      nil
    end
  end
end
