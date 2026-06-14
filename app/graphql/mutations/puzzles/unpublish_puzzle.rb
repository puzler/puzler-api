module Mutations
  module Puzzles
    class UnpublishPuzzle < Mutations::BaseMutation
      description "Unpublish a puzzle, returning it to draft so solvers can no longer reach it"

      argument :id, ID, required: true, description: "ID of the puzzle"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The unpublished puzzle"

      def resolve(id:)
        require_auth!
        puzzle = current_user.puzzles.find_by(id:)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        if puzzle.update(published_version: nil, status: :draft)
          { puzzle:, errors: [] }
        else
          { puzzle: nil, errors: puzzle.errors.full_messages }
        end
      end
    end
  end
end
