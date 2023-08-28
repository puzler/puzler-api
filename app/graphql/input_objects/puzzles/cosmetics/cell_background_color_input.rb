# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Cosmetics
      class CellBackgroundColorInput < SingleCellInput
        description 'Input for a single cell background color cosmetic'

        argument :colors,
                 [ColorInput],
                 required: true,
                 description: 'The background colors for the cell'
      end
    end
  end
end
