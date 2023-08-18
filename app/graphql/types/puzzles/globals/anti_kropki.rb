# frozen_string_literal: true

module Types
  module Puzzles
    module Globals
      class AntiKropki < BaseType
        description 'Anti-Kropki Global Constraint Settings'
        field :anti_black, Boolean, null: false, description: 'All black dots given'
        field :anti_white, Boolean, null: false, description: 'All white dots given (non-consecutive)'
      end
    end
  end
end
