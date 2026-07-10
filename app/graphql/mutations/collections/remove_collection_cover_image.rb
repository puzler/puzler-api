module Mutations
  module Collections
    # Remove a collection's cover image. Purges async so the request stays fast.
    class RemoveCollectionCoverImage < Mutations::BaseMutation
      description "Remove a collection's cover image"

      argument :collection_id, ID, required: true, description: "Collection to update"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(collection_id:)
        collection = require_owned!(:collections, "Collection", id: collection_id)

        collection.cover_image.purge_later if collection.cover_image.attached?
        { collection: collection.reload, errors: [] }
      end
    end
  end
end
