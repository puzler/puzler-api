# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Cosmetics
      class CustomLineInput < BaseLineInput
        description 'Input for a Custom Cosmetic Line'

        argument :color, ColorInput, required: true, description: 'Line Color'
        argument :width, Float, required: true, description: 'The width of the line'
      end
    end
  end
end
