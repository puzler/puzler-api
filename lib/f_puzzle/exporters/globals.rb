# frozen_string_literal: true

module FPuzzle
  module Exporters
    class Globals
      class << self
        include ExporterHelpers

        def parse(puzzle)
          globals = puzzle.global_constraints

          {
            negative: negative_for(globals),
            antiknight: globals.chess&.knight,
            antiking: globals.chess&.king,
            'diagonal+': globals.diagonals&.positive,
            'diagonal-': globals.diagonals&.negative,
            nonconsecutive: globals.anti_kropki&.anti_white,
            disjointgroups: globals.disjoint_sets&.enabled
          }
        end

        private

        def negative_for(globals)
          list = []

          list.push('ratio') if globals.anti_kropki&.anti_black
          list.push('xv') if globals.anti_x_v&.anti_x || globals.anti_x_v&.anti_v

          list
        end
      end
    end
  end
end
