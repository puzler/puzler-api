# frozen_string_literal: true

module FPuzzle
  module Parsers
    class Globals
      class << self
        def parse(puzzle_data)
          remap_data(
            puzzle_data,
            chess: { king: :antiking, knight: :antiknight },
            # :'diagonal-' gets converted to diagonal_ when we .underscore it
            diagonals: { positive: :'diagonal+', negative: :diagonal_ },
            anti_kropki: { antiwhite: :nonconsecutive, anti_black: [:negative, 'ratio'] },
            anti_x_v: { anti_x: [:negative, 'xv'], anti_v: [:negative, 'xv'] },
            disjoint_sets: { enabled: :disjointgroups }
          ).each_with_object({}) do |(global_key, settings), output|
            next unless settings.values.any?

            output[global_key] = settings.transform_values { |v| v || false }
          end
        end

        private

        def remap_data(data, **remap_groups)
          remap_groups.transform_values do |group|
            group.transform_values do |input_key, string_key|
              if string_key
                data[input_key]&.include? string_key
              else
                data[input_key]
              end
            end
          end
        end
      end
    end
  end
end
