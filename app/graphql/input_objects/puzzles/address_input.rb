# frozen_string_literal: true

module InputObjects
  module Puzzles
    class AddressInput < BaseInputObject
      description 'Input for the location of an element'

      argument :column, Float, required: true, description: 'Horizontal Location'
      argument :row, Float, required: true, description: 'Vertical Location'
    end
  end
end
