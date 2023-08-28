# frozen_string_literal: true

module InputObjects
  module Puzzles
    class CosmeticElementsInput < BaseInputObject
      description 'Input for the collection of cosmetic elements in a puzzle'

      argument :cages, [Cosmetics::CageInput], required: false, description: 'Cosmetic Cages'
      argument :circles, [Cosmetics::CosmeticShapeInput], required: false, description: 'Cosmetic Circles'
      argument :lines, [Cosmetics::CustomLineInput], required: false, description: 'Cosmetic Lines'
      argument :rectangles, [Cosmetics::CosmeticShapeInput], required: false, description: 'Cosmetic Rectangles'
      argument :text, [Cosmetics::TextInput], required: false, description: 'Cosmetic Text'
    end
  end
end
