# frozen_string_literal: true

module Types
  module Puzzles
    class LocalConstraints < BaseType
      description 'The set of local constraints for a puzzle'

      field :extra_regions,
            [Locals::ExtraRegion],
            null: true,
            description: 'Extra Regions'

      field :odd_cells,
            [Locals::OddCell],
            null: true,
            description: 'Odd Cells'

      field :even_cells,
            [Locals::EvenCell],
            null: true,
            description: 'EvenCell'

      field :thermometers,
            [Locals::Thermometer],
            null: true,
            description: 'Thermometer Constraint'

      field :palindrome_lines,
            [Locals::PalindromeLine],
            null: true,
            description: 'Palindrome Lines'

      field :renban_lines,
            [Locals::RenbanLine],
            null: true,
            description: 'Renban Lines'

      field :german_whisper_lines,
            [Locals::GermanWhisperLine],
            null: true,
            description: 'German Whisper Lines'

      field :dutch_whisper_lines,
            [Locals::DutchWhisperLine],
            null: true,
            description: 'Dutch Whisper Lines'

      field :region_sum_lines,
            [Locals::RegionSumLine],
            null: true,
            description: 'Region Sum Lines'

      field :column_index_cells,
            [Locals::ColumnIndexCell],
            null: true,
            description: 'Column Index Cells'

      field :row_index_cells,
            [Locals::RowIndexCell],
            null: true,
            description: 'Row Index Cells'

      field :killer_cages,
            [Locals::KillerCage],
            null: true,
            description: 'Killer Cages'

      field :little_killer_sums,
            [Locals::LittleKillerSum],
            null: true,
            description: 'Little Killer Sums'

      field :sandwich_sums,
            [Locals::SandwichSum],
            null: true,
            description: 'Sandwich Sums'

      field :x_sums,
            [Locals::XSum],
            null: true,
            description: 'X Sums'

      field :skyscrapers,
            [Locals::Skyscraper],
            null: true,
            description: 'Skyscrapers'

      field :difference_dots,
            [Locals::DifferenceDot],
            null: true,
            description: 'Difference Dots'

      field :ratio_dots,
            [Locals::RatioDot],
            null: true,
            description: 'Ratio Dots'

      field :clones,
            [Locals::Clone],
            null: true,
            description: 'Clones'

      field :arrows,
            [Locals::Arrow],
            null: true,
            description: 'Arrow Constraint'

      field :between_lines,
            [Locals::BetweenLine],
            null: true,
            description: 'Between Lines'

      field :min_cells,
            [Locals::MinCell],
            null: true,
            description: 'Minimum Cells'

      field :max_cells,
            [Locals::MaxCell],
            null: true,
            description: 'Maximum Cells'

      field :xv,
            [Locals::XV],
            null: true,
            description: 'XV Constraints'

      field :quadruples,
            [Locals::Quadruple],
            null: true,
            description: 'Quadruples'
    end
  end
end
