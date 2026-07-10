module Mutations
  module Collections
    # Upload an image to embed in a collection's rich page body (multipart). The
    # image is downscaled, EXIF-stripped, and stored as WebP, then attached to
    # the collection so it can be cleaned up later. Returns the hosted URL the
    # editor inserts as <img src> — which the sanitizer then accepts.
    class UploadCollectionDescriptionImage < Mutations::BaseMutation
      description "Upload and store an image for a collection's rich page body"

      MAX_BYTES = 8.megabytes
      MAX_DIMENSION = 1600

      argument :collection_id, ID, required: true, description: "Collection to attach the image to"
      argument :file, ::ApolloUploadServer::Upload, required: true,
        description: "The image file (PNG, JPEG, or WebP, max 8MB)"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :url, String, null: true, description: "Hosted URL of the stored image"

      def resolve(file:, collection_id:)
        collection = require_owned!(:collections, "Collection", id: collection_id)

        processed = ImageNormalizer.new(file, max_bytes: MAX_BYTES, max_dimension: MAX_DIMENSION, label: "Image").call
        blob = ActiveStorage::Blob.create_and_upload!(
          io: processed, filename: "description.webp", content_type: "image/webp"
        )
        collection.description_images.attach(blob)
        { url: blob_url(blob), errors: [] }
      rescue ImageNormalizer::InvalidImage => e
        { url: nil, errors: [ e.message ] }
      end

      private

      def blob_url(blob)
        Rails.application.routes.url_helpers.rails_blob_url(blob, host: DescriptionImageHost.base_url)
      end
    end
  end
end
