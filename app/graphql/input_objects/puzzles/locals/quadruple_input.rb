# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Locals
      class QuadrupleInput < MultiCellInput
        description 'Input for a quadruple clue'

        argument :values, [Integer], required: true, description: 'The values in the Quadruple'
      end
    end
  end
end
