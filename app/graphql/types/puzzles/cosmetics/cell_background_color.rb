# frozen_string_literal: true

module Types
  module Puzzles
    module Cosmetics
      class CellBackgroundColor < BaseType
        implements Interfaces::Puzzles::SingleCell
        description 'A background color for a single cell'
        field :color, Color, null: false, description: 'The background color'
      end
    end
  end
end
