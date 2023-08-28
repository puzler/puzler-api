# frozen_string_literal: true

module Types
  module Puzzles
    module Cosmetics
      class CellBackgroundColor < BaseType
        implements Interfaces::Puzzles::SingleCell
        description 'A background color for a single cell'
        field :colors, [Color], null: false, description: 'The background colors'
      end
    end
  end
end
