# frozen_string_literal: true

module InputObjects
  module Puzzles
    class LocalConstraintsInput < BaseInputObject
      description 'Input for the collection of local constraints for a puzzle'

      argument :column_index_cells, [SingleCellInput], required: false, description: 'Column Index Cells'
      argument :even_cells, [SingleCellInput], required: false, description: 'Even Cells'
      argument :max_cells, [SingleCellInput], required: false, description: 'Maximum Cells'
      argument :min_cells, [SingleCellInput], required: false, description: 'Minimum Cells'
      argument :odd_cells, [SingleCellInput], required: false, description: 'Odd Cells'
      argument :row_index_cells, [SingleCellInput], required: false, description: 'Row Index Cells'

      argument :between_lines, [BaseLineInput], required: false, description: 'Between Lines'
      argument :dutch_whisper_lines, [BaseLineInput], required: false, description: 'Dutch Whisper Lines'
      argument :german_whisper_lines, [BaseLineInput], required: false, description: 'German Whisper Lines'
      argument :palindrome_lines, [BaseLineInput], required: false, description: 'Palindrome Lines'
      argument :region_sum_lines, [BaseLineInput], required: false, description: 'Region Sum Lines'
      argument :renban_lines, [BaseLineInput], required: false, description: 'Renban Lines'

      argument :clones, [Locals::CloneInput], required: false, description: 'Clone Groups'
      argument :extra_regions, [MultiCellInput], required: false, description: 'Extra Regions'
      argument :killer_cages, [Locals::KillerCageInput], required: false, description: 'Killer Cages'

      argument :arrows, [Locals::ArrowInput], required: false, description: 'Arrows'
      argument :thermometers, [Locals::ThermometerInput], required: false, description: 'Thermometers'

      argument :little_killer_sums, [Locals::LittleKillerSumInput], required: false, description: 'Little Killers'
      argument :sandwich_sums, [NumberOutsideGridInput], required: false, description: 'Sandwich Sums'
      argument :skyscrapers, [NumberOutsideGridInput], required: false, description: 'Skyscrapers'
      argument :x_sums, [NumberOutsideGridInput], required: false, description: 'X Sums'

      argument :difference_dots, [Locals::DifferenceDotInput], required: false, description: 'Difference Dots'
      argument :quadruples, [Locals::QuadrupleInput], required: false, description: 'Quadruples'
      argument :ratio_dots, [Locals::RatioDotInput], required: false, description: 'Ratio Dots'
      argument :xv, [Locals::XVInput], required: false, description: 'XV Elements'
    end
  end
end
