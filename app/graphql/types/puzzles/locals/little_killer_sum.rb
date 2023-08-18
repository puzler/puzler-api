# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class LittleKillerDirection < BaseType
        field :left, Boolean, null: false, description: 'Left or Right'
        field :top, Boolean, null: false, description: 'Top or Bottom'

        description 'The Direction of a little killer'
      end

      class LittleKillerSum < BaseType
        implements Interfaces::Puzzles::NumberOutsideGrid

        field :direction,
              LittleKillerDirection,
              null: false,
              description: 'Direction the little killer arrow is pointing'

        description 'A Little Killer Clue'
      end
    end
  end
end
