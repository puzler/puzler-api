# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Locals
      class LittleKillerDirectionInput < BaseInputObject
        description 'Input for the direction of a little killer arrow'

        argument :left, Boolean, required: true, description: 'Left or Right'
        argument :top, Boolean, required: true, description: 'Top or Bottom'
      end

      class LittleKillerSumInput < NumberOutsideGridInput
        description 'Input for a little killer sum'

        argument :direction,
                 LittleKillerDirectionInput,
                 required: true,
                 description: 'Direction of the arrow'
      end
    end
  end
end
