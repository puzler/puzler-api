# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Globals
      class AntiKropkiInput < BaseInputObject
        description 'Input for an Anti-Kropki Global Constraint'
        argument :anti_black, Boolean, required: true, description: 'All black dots given'
        argument :anti_white, Boolean, required: true, description: 'All white dots given'
      end
    end
  end
end
