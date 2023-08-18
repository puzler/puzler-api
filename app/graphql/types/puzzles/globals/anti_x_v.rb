# frozen_string_literal: true

module Types
  module Puzzles
    module Globals
      class AntiXV < BaseType
        description 'Anti XV Global Setting'
        field :anti_v, Boolean, null: false, description: "All V's are given"
        field :anti_x, Boolean, null: false, description: "All X's are given"
      end
    end
  end
end
