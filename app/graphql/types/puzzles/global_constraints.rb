# frozen_string_literal: true

module Types
  module Puzzles
    class GlobalConstraints < BaseType
      description 'The collection of global constraints for a puzzle'

      field :anti_kropki, Globals::AntiKropki, null: true, description: 'Anti-Kropki sudoku global'
      field :anti_x_v, Globals::AntiXV, null: true, description: 'Anti-XV sudoku global'
      field :chess, Globals::Chess, null: true, description: 'Anti-Chess move sudoku global'
      field :diagonals, Globals::Diagonals, null: true, description: 'Diagonal sudoku global'
      field :disjoint_sets,
            Globals::DisjointSets,
            null: true,
            description: 'Disjoint sets sudoku global'
    end
  end
end
