module Mutations
  module Folders
    class DeleteFolder < Mutations::BaseMutation
      description "Delete a folder; its puzzles are kept and simply unfiled"

      argument :id, ID, required: true, description: "ID of the folder to delete"

      field :errors, [ String ], null: false, description: "Errors, if any"
      field :success, Boolean, null: false, description: "Whether the folder was deleted"

      def resolve(id:)
        require_auth!
        folder = current_user.folders.find_by(id:)
        raise GraphQL::ExecutionError, "Folder not found" unless folder

        folder.destroy
        { success: true, errors: [] }
      end
    end
  end
end
