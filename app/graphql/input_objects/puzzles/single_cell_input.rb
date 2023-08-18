# frozen_string_literal: true

module InputObjects
  module Puzzles
    class SingleCellInput < BaseInputObject
      description 'Input for an element that references a single cell'
      argument :cell, AddressInput, required: true, description: 'The cell for the element'
    end
  end
end
