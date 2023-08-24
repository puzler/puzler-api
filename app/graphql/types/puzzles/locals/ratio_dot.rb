# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class RatioDot < BaseType
        implements Interfaces::Puzzles::CellConnector
        field :ratio, Integer, null: true, description: 'Ratio of the connected dots'

        description 'A Ratio Dot'
      end
    end
  end
end
