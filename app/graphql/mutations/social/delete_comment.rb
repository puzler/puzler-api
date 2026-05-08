module Mutations
  module Social
    class DeleteComment < Mutations::BaseMutation
      description "Delete a comment posted by the current user"

      argument :id, ID, required: true,
        description: "ID of the comment to delete"

      field :success, Boolean, null: false,
        description: "True when the comment was successfully deleted"

      def resolve(id:)
        require_auth!
        comment = current_user.comments.find_by(id:)
        raise GraphQL::ExecutionError, "Comment not found" unless comment

        comment.destroy
        { success: true }
      end
    end
  end
end
