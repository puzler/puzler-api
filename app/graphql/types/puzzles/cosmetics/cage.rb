# frozen_string_literal: true

module Types
  module Puzzles
    module Cosmetics
      class Cage < BaseType
        description 'A Cosmetic Cage Element'
        implements Interfaces::Puzzles::MultiCell
        field :cage_color, Color, null: false, description: 'Color of the cage'
        field :text, String, null: true, description: 'Text in the top corner of the cage'
        field :text_color, Color, null: true, description: 'Text color'
      end
    end
  end
end
