module Mutations
  module Puzzles
    class RevokePuzzleAccess < Mutations::BaseMutation
      description "Remove a user's access to a puzzle"

      argument :puzzle_id, ID, required: true, description: "ID of the puzzle"
      argument :user_id, ID, required: true, description: "ID of the user to revoke"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The puzzle, with its updated grants"

      def resolve(puzzle_id:, user_id:)
        require_auth!
        puzzle = current_user.puzzles.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        puzzle.access_grants.where(user_id:).destroy_all
        { puzzle:, errors: [] }
      end
    end
  end
end
