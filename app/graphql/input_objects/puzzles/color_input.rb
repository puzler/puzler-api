# frozen_string_literal: true

module InputObjects
  module Puzzles
    class ColorInput < BaseInputObject
      description 'Input for the color of an element'

      argument :blue, Float, required: true, description: 'Blue value (0-255)'
      argument :green, Float, required: true, description: 'Green value (0-255)'
      argument :opacity, Float, required: true, description: 'Opacity (0-1)'
      argument :red, Float, required: true, description: 'Red value (0-255)'
    end
  end
end
