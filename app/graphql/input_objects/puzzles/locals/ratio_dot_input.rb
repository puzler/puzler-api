# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Locals
      class RatioDotInput < MultiCellInput
        description 'Input for a ratio dot'

        argument :ratio, Integer, required: false, description: 'The ratio of the two cells'
      end
    end
  end
end
