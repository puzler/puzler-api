module Mutations
  module Puzzles
    class DeletePuzzle < Mutations::BaseMutation
      description "Permanently delete a puzzle owned by the current user"

      argument :id, ID, required: true,
        description: "ID of the puzzle to delete"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :success, Boolean, null: false,
        description: "True when the puzzle was successfully deleted"

      def resolve(id:)
        require_auth!
        puzzle = current_user.puzzles.find_by(id:)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        puzzle.destroy
        { success: true, errors: [] }
      end
    end
  end
end
