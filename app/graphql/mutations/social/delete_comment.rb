module Mutations
  module Social
    class DeleteComment < Mutations::BaseMutation
      description "Delete a comment posted by the current user"

      argument :id, ID, required: true,
        description: "ID of the comment to delete"

      field :success, Boolean, null: false,
        description: "True when the comment was successfully deleted"

      def resolve(id:)
        comment = require_owned!(:comments, "Comment", id:)

        comment.destroy
        { success: true }
      end
    end
  end
end
