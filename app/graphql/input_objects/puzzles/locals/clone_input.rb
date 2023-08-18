# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Locals
      class CloneInput < MultiCellInput
        description 'Input for a clone group'

        argument :clone_cells,
                 [[AddressInput]],
                 required: true,
                 description: 'The cells that are cloned'
      end
    end
  end
end
