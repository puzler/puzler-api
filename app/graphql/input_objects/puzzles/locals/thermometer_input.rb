# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Locals
      class ThermometerInput < BaseInputObject
        description 'Input for a thermometer element'

        argument :bulb,
                 AddressInput,
                 required: true,
                 description: 'Location of the bulb'

        argument :lines,
                 [[AddressInput]],
                 required: true,
                 description: 'Lines from the bulb'
      end
    end
  end
end
