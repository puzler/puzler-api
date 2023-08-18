# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Globals
      class AntiXVInput < BaseInputObject
        description 'Input for an Anti-XV Global Constraint'
        argument :anti_v, Boolean, required: true, description: "All V's are given"
        argument :anti_x, Boolean, required: true, description: "All X's are given"
      end
    end
  end
end
