module Mutations
  module Puzzles
    class DeletePuzzleVersion < Mutations::BaseMutation
      description "Delete a puzzle version (the currently published version cannot be deleted)"

      argument :id, ID, required: true, description: "ID of the version to delete"

      field :errors, [ String ], null: false, description: "Errors, if any"
      field :success, Boolean, null: false, description: "Whether the version was deleted"

      def resolve(id:)
        require_auth!
        version = PuzzleVersion.joins(:puzzle).find_by(id:, puzzles: { author_id: current_user.id })
        raise GraphQL::ExecutionError, "Version not found" unless version

        if version.published?
          return {
            success: false,
            errors: [ "Cannot delete the published version; unpublish or publish another version first" ]
          }
        end

        version.destroy
        { success: true, errors: [] }
      end
    end
  end
end
