# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class XV < BaseType
        implements Interfaces::Puzzles::MultiCell
        field :location, Address, null: false, description: 'Visual location of the element'
        field :xv_type, Enums::Puzzles::XVTypes, null: true, description: 'Type of XV'

        description 'An XV clue'
      end
    end
  end
end
