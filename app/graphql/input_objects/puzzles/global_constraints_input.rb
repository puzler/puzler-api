# frozen_string_literal: true

module InputObjects
  module Puzzles
    class GlobalConstraintsInput < BaseInputObject
      description 'Input for the collection of global constraints for a puzzle'

      argument :anti_kropki, Globals::AntiKropkiInput, required: false, description: 'Anti-Kropki global'
      argument :anti_x_v, Globals::AntiXVInput, required: false, description: 'Anti-XV sudoku'
      argument :chess, Globals::ChessInput, required: false, description: 'Anti-Chess global'
      argument :diagonals, Globals::DiagonalsInput, required: false, description: 'Diagonal global'
      argument :disjoint_sets,
               Globals::DisjointSetsInput,
               required: false,
               description: 'Disjoint Sets global'
    end
  end
end
