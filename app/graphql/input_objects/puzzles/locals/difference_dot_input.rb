# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Locals
      class DifferenceDotInput < MultiCellInput
        description 'Input for a difference dot'

        argument :difference, Integer, required: false, description: 'The difference of the two cells'
      end
    end
  end
end
