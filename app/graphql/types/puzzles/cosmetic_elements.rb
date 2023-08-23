# frozen_string_literal: true

module Types
  module Puzzles
    class CosmeticElements < BaseType
      description 'The collection of cosmetic elements for a puzzle'

      field :cages, [Cosmetics::Cage], null: true, description: 'Cosmetic Cages'
      field :cell_background_colors,
            [Cosmetics::CellBackgroundColor],
            null: true,
            description: 'A list of cells with a background color'
      field :circles, [Cosmetics::Circle], null: true, description: 'Cosmetic Circle'
      field :lines, [Cosmetics::CustomLine], null: true, description: 'Cosmetic Lines'
      field :rectangles, [Cosmetics::Rectangle], null: true, description: 'Cosmetic Rectangles'
      field :text, [Cosmetics::Text], null: true, description: 'Cosmetic Text'
    end
  end
end
