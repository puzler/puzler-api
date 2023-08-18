# frozen_string_literal: true

module Types
  module Puzzles
    class Color < BaseType
      description 'A Color used for a puzzle element'
      field :blue, Float, null: false, description: 'Blue value (0-255)'
      field :green, Float, null: false, description: 'Green value (0-255)'
      field :opacity, Float, null: false, description: 'Opacity value (0-1)'
      field :red, Float, null: false, description: 'Red value (0-255)'
    end
  end
end
