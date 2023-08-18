# frozen_string_literal: true

module InputObjects
  module Puzzles
    class MultiCellInput < BaseInputObject
      description 'Input for an element that references multiple cells'

      argument :cells,
               [AddressInput],
               required: true,
               description: 'Cells included in the element'
    end
  end
end
