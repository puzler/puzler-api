# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Cosmetics
      class CosmeticShapeInput < BaseInputObject
        description 'Input for a cosmetic shape element'

        argument :address,
                 AddressInput,
                 required: true,
                 description: 'Center point of the shape'

        argument :height, Float, required: true, description: 'Height of the shape'
        argument :width, Float, required: true, description: 'Width of the shape'

        argument :fill_color,
                 ColorInput,
                 required: true,
                 description: 'Color to fill the shape'

        argument :outline_color,
                 ColorInput,
                 required: true,
                 description: "Color of the shape's outline"

        argument :text, String, required: false, description: 'Text to place inside the shape'
        argument :text_color,
                 ColorInput,
                 required: false,
                 description: 'Color of the text inside the shape'

        argument :angle, Float, required: false, description: 'Angle of rotation'
      end
    end
  end
end
