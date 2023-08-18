# frozen_string_literal: true

module Types
  module Puzzles
    module Globals
      class Chess < BaseType
        description 'Chess Global Constraint Settings'
        field :king, Boolean, null: false, description: 'Anti-King move'
        field :knight, Boolean, null: false, description: 'Anti-Knight move'
      end
    end
  end
end
