# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class Arrow < BaseType
        field :circle_cells, [Address], null: false, description: 'Arrow circle cells'
        field :lines, [Address], null: false, description: 'Arrow lines'

        description 'An Arrow clue'
      end
    end
  end
end
