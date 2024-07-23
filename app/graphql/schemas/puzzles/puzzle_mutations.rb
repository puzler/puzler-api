# frozen_string_literal: true

module Schemas
  module Puzzles
    module PuzzleMutations
      include Interfaces::BaseInterface

      description 'Base Mutation object for Puzzles'

      field :save_puzzle,
            mutation: Mutations::Puzzles::SavePuzzle,
            description: 'Save a puzzle to the DB'
    end
  end
end
