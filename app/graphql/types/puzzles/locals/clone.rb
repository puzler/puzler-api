# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class Clone < BaseType
        implements Interfaces::Puzzles::MultiCell
        field :clone_cells, [[Address]], null: false, description: 'Clone locations'

        description 'A Clone Group'
      end
    end
  end
end
