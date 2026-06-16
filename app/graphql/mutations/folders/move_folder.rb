module Mutations
  module Folders
    class MoveFolder < Mutations::BaseMutation
      description "Reparent a folder, or pass a null parent to move it to the top level"

      argument :id, ID, required: true, description: "Folder to move"
      argument :parent_id, ID, required: false, description: "New parent folder, or null for top level"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :folder, Types::Objects::FolderType, null: true, description: "The moved folder"

      def resolve(id:, parent_id: nil)
        require_auth!
        folder = current_user.folders.find_by(id:)
        raise GraphQL::ExecutionError, "Folder not found" unless folder

        if parent_id.present? && !current_user.folders.exists?(id: parent_id)
          raise GraphQL::ExecutionError, "Parent folder not found"
        end

        # The model rejects cycles (parent can't be the folder or a descendant).
        if folder.update(parent_id:)
          { folder:, errors: [] }
        else
          { folder: nil, errors: folder.errors.full_messages }
        end
      end
    end
  end
end
