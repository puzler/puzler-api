# frozen_string_literal: true

module Types
  module Puzzles
    module Cosmetics
      class Circle < BaseType
        description 'A Cosmetic Circle Element'
        implements Interfaces::Puzzles::CosmeticShape
      end
    end
  end
end
