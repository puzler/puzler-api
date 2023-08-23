# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class RatioDot < BaseType
        implements Interfaces::Puzzles::MultiCell
        field :location, Address, null: false, description: 'Visual location of the element'
        field :ratio, Integer, null: true, description: 'Ratio of the connected dots'

        description 'A Ratio Dot'
      end
    end
  end
end
