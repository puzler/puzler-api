# frozen_string_literal: true

module Types
  module Puzzles
    class SingleCellConstraint < BaseType
      field :address, Address, null: false, description: 'Cell Address'

      description 'A Constraint for a single cell'
    end
  end
end
