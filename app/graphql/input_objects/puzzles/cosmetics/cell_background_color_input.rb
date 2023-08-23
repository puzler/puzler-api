# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Cosmetics
      class CellBackgroundColorInput < SingleCellInput
        description 'Input for a single cell background color cosmetic'

        argument :color,
                 ColorInput,
                 required: true,
                 description: 'The background color for the cell'
      end
    end
  end
end
