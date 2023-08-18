# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class XV < BaseType
        implements Interfaces::Puzzles::MultiCell
        field :xv_type, Enums::Puzzles::XVTypes, null: false, description: 'Type of XV'

        description 'An XV clue'
      end
    end
  end
end
