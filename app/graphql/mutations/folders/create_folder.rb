module Mutations
  module Folders
    class CreateFolder < Mutations::BaseMutation
      description "Create a folder for organizing your puzzles"

      argument :name, String, required: true, description: "Folder name"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :folder, Types::Objects::FolderType, null: true, description: "The new folder"

      def resolve(name:)
        require_auth!
        position = (current_user.folders.maximum(:position) || -1) + 1
        folder = current_user.folders.build(name:, position:)

        if folder.save
          { folder:, errors: [] }
        else
          { folder: nil, errors: folder.errors.full_messages }
        end
      end
    end
  end
end
