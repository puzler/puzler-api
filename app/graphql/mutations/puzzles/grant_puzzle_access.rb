module Mutations
  module Puzzles
    class GrantPuzzleAccess < Mutations::BaseMutation
      description "Give a specific user access to a puzzle, by username"

      argument :puzzle_id, ID, required: true, description: "ID of the puzzle"
      argument :username, String, required: true, description: "Username of the user to grant access to"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The puzzle, with its updated grants"

      def resolve(puzzle_id:, username:)
        require_auth!
        puzzle = current_user.puzzles.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        user = User.find_by("LOWER(username) = ?", username.downcase)
        return { puzzle: nil, errors: [ "No user named #{username}" ] } unless user
        return { puzzle: nil, errors: [ "You already have access to your own puzzle" ] } if user.id == current_user.id

        puzzle.access_grants.find_or_create_by(user:) { |grant| grant.granted_by = current_user }
        { puzzle:, errors: [] }
      end
    end
  end
end
