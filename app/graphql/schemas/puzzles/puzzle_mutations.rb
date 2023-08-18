# frozen_string_literal: true

module Schemas
  module Puzzles
    module PuzzleMutations
      include Interfaces::BaseInterface

      description 'Base Mutation object for Puzzles'

      field :create_puzzle,
            mutation: Mutations::Puzzles::CreatePuzzle,
            description: 'Create a Puzzle'
    end
  end
end
