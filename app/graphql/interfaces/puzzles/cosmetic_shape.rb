# frozen_string_literal: true

module Interfaces
  module Puzzles
    module CosmeticShape
      include BaseInterface

      description 'An element that creates a shape in the grid'

      field :address,
            Types::Puzzles::Address,
            null: false,
            description: 'The center point of the shape'

      field :angle, Float, null: true, description: 'Shape rotation angle'
      field :fill_color, Types::Puzzles::Color, null: false, description: 'Shape color'
      field :height, Float, null: false, description: 'Shape height'
      field :outline_color, Types::Puzzles::Color, null: false, description: 'Shape outline color'
      field :text, String, null: true, description: 'Text inside shape'
      field :text_color, Types::Puzzles::Color, null: true, description: 'Text color'
      field :width, Float, null: false, description: 'Shape width'
    end
  end
end
