# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Locals
      class KillerCageInput < MultiCellInput
        description 'Input for a killer cage'

        argument :value, Integer, required: false, description: 'The value of the Killer Cage'
      end
    end
  end
end
