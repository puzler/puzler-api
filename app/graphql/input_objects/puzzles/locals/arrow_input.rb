# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Locals
      class ArrowInput < BaseInputObject
        description 'Input for an Arrow element'

        argument :circle_cells,
                 [AddressInput],
                 required: true,
                 description: 'Cells included in the Arrow Circle'

        argument :lines, [[AddressInput]], required: true, description: 'Arrow lines'
      end
    end
  end
end
