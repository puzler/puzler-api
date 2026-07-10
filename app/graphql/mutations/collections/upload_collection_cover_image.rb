module Mutations
  module Collections
    # Upload or replace a collection's cover image (multipart). Normalized to
    # WebP with metadata stripped; the hero/card crops are ActiveStorage
    # variants. Attaching replaces any previous cover (has_one_attached).
    class UploadCollectionCoverImage < Mutations::BaseMutation
      description "Upload or replace a collection's cover image"

      argument :collection_id, ID, required: true, description: "Collection to update"
      argument :file, ::ApolloUploadServer::Upload, required: true,
        description: "The image file (PNG, JPEG, or WebP, max 8MB)"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(file:, collection_id:)
        collection = require_owned!(:collections, "Collection", id: collection_id)

        processed = CoverImageNormalizer.new(file).call
        collection.cover_image.attach(
          io: processed, filename: "cover.webp", content_type: "image/webp"
        )
        { collection: collection.reload, errors: [] }
      rescue CoverImageNormalizer::InvalidImage => e
        { collection: nil, errors: [ e.message ] }
      end
    end
  end
end
