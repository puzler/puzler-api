# frozen_string_literal: true

module Mutations
  module Puzzles
    class CreatePuzzle < BaseMutation
      description 'Save a new puzzle'

      argument :puzzle,
               InputObjects::PuzzleInput,
               description: 'The Puzzle to save'

      field :puzzle, Types::Puzzle, null: true, description: 'The created puzzle'
      authenticated true

      def resolve(puzzle:)
        record = Puzzle.create(
          puzzle.merge(
            user_id: current_user.id
          )
        )

        return errors_for(record) if record.errors.any?

        {
          success: true,
          puzzle: record
        }
      end

      private

      def create_puzzle(puzzle_args)
        Puzzle.create(
          puzzle_args.merge(
            user_id: current_user.id
          )
        )
      end
    end
  end
end
