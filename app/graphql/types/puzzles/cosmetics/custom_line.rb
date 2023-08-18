# frozen_string_literal: true

module Types
  module Puzzles
    module Cosmetics
      class CustomLine < BaseType
        description 'A Custom Cosmetic Line'
        implements Interfaces::Puzzles::Line

        field :color, Color, null: false, description: 'Line color'
        field :width, Float, null: false, description: 'Line thickness'
      end
    end
  end
end
