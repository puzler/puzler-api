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
        puzzle = require_owned!(:puzzles, "Puzzle", id:)

        was_published = puzzle.published?
        puzzle.destroy
        # A removed published puzzle changes the author's setter score.
        current_user.recompute_setter_stats! if was_published
        { success: true, errors: [] }
      end
    end
  end
end
