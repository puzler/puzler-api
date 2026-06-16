module Mutations
  module Folders
    class MoveCollectionToFolder < Mutations::BaseMutation
      description "File a collection into a folder, or pass a null folder to unfile it"

      argument :collection_id, ID, required: true, description: "Collection to move"
      argument :folder_id, ID, required: false, description: "Target folder, or null to unfile"

      field :collection, Types::Objects::CollectionType, null: true, description: "The moved collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(collection_id:, folder_id: nil)
        require_auth!
        collection = current_user.collections.find_by(id: collection_id)
        raise GraphQL::ExecutionError, "Collection not found" unless collection

        if folder_id.present? && !current_user.folders.exists?(id: folder_id)
          raise GraphQL::ExecutionError, "Folder not found"
        end

        collection.update(folder_id:)
        { collection:, errors: [] }
      end
    end
  end
end
