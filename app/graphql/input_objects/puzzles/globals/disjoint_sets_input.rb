# frozen_string_literal: true

module InputObjects
  module Puzzles
    module Globals
      class DisjointSetsInput < BaseInputObject
        description 'Input for a Disjoint Set Global Constraint'
        argument :enabled, Boolean, required: true, description: 'Disjoint Sets restriction'
      end
    end
  end
end
