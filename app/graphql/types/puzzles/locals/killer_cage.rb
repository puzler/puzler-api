# frozen_string_literal: true

module Types
  module Puzzles
    module Locals
      class KillerCage < BaseType
        implements Interfaces::Puzzles::MultiCell
        field :value, Integer, null: true, description: 'Value of the cage'

        description 'A Killer Cage'
      end
    end
  end
end
