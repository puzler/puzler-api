module Mutations
  module Folders
    class RenameFolder < Mutations::BaseMutation
      description "Rename one of your folders"

      argument :id, ID, required: true, description: "ID of the folder"
      argument :name, String, required: true, description: "New name"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :folder, Types::Objects::FolderType, null: true, description: "The updated folder"

      def resolve(id:, name:)
        require_auth!
        folder = current_user.folders.find_by(id:)
        raise GraphQL::ExecutionError, "Folder not found" unless folder

        if folder.update(name:)
          { folder:, errors: [] }
        else
          { folder: nil, errors: folder.errors.full_messages }
        end
      end
    end
  end
end
