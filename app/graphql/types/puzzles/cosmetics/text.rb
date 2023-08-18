# frozen_string_literal: true

module Types
  module Puzzles
    module Cosmetics
      class Text < BaseType
        description 'A Cosmetic Text Element'
        field :address, Address, null: false, description: 'Text Location'
        field :angle, Float, null: true, description: 'Text Rotation Angle'
        field :font_color, Color, null: true, description: 'Font Color'
        field :size, Float, null: false, description: 'Text Size'
        field :text, String, null: true, description: 'Text to Display'
      end
    end
  end
end
