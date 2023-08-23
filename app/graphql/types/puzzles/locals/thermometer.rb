# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class Thermometer < BaseType
        field :bulb, Address, null: false, description: 'Thermo bulb location'
        field :lines, [[Address]], null: false, description: 'Thermo lines'

        description 'A Thermometer'
      end
    end
  end
end
