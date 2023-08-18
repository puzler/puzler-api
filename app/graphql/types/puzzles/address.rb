# frozen_string_literal: true

module Types
  module Puzzles
    class Address < BaseType
      description 'An address used to position an element'
      field :column, Float, null: false, description: 'Column Location'
      field :row, Float, null: false, description: 'Row Location'
    end
  end
end
