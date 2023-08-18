# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class DifferenceDot < BaseType
        implements Interfaces::Puzzles::MultiCell
        field :difference, Integer, null: true, description: 'Difference of the touching cells'

        description 'A Difference Dot'
      end
    end
  end
end
