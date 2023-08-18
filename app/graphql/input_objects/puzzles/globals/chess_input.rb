# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Globals
      class ChessInput < BaseInputObject
        description 'Input for a Chess Move Global Constraint'
        argument :king, Boolean, required: true, description: 'Anti-King restriction'
        argument :knight, Boolean, required: true, description: 'Anti-Knight restriction'
      end
    end
  end
end
