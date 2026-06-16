module Mutations
  module Folders
    class CreateFolder < Mutations::BaseMutation
      description "Create a folder for organizing your puzzles"

      argument :name, String, required: true, description: "Folder name"
      argument :parent_id, ID, required: false, description: "Parent folder to nest under, or null for top level"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :folder, Types::Objects::FolderType, null: true, description: "The new folder"

      def resolve(name:, parent_id: nil)
        require_auth!
        if parent_id.present? && !current_user.folders.exists?(id: parent_id)
          raise GraphQL::ExecutionError, "Parent folder not found"
        end

        position = (current_user.folders.where(parent_id:).maximum(:position) || -1) + 1
        folder = current_user.folders.build(name:, position:, parent_id:)

        if folder.save
          { folder:, errors: [] }
        else
          { folder: nil, errors: folder.errors.full_messages }
        end
      end
    end
  end
end
