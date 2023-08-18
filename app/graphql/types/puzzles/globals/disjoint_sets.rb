# frozen_string_literal: true

module Types
  module Puzzles
    module Globals
      class DisjointSets < BaseType
        description 'Disjoint Sets Global Settings'

        field :enabled, Boolean, null: false, description: 'Disjoint sets enabled'
      end
    end
  end
end
