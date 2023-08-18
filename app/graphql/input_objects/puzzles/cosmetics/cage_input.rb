# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Cosmetics
      class CageInput < MultiCellInput
        description 'Input for a cosmetic cage'

        argument :text,
                 String,
                 required: false,
                 description: 'Text to place in the corner of the cage'

        argument :text_color,
                 ColorInput,
                 required: false,
                 description: 'Color of the corner text'

        argument :cage_color,
                 ColorInput,
                 required: true,
                 description: 'Color of the cage'
      end
    end
  end
end
