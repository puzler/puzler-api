module Mutations
  module Collections
    # Upload an image to embed in a story page's rich body (multipart). Same
    # pipeline as puzzle/collection description images: downscaled, EXIF
    # stripped, stored as WebP, attached for later cleanup.
    class UploadStoryPageImage < Mutations::BaseMutation
      description "Upload and store an image for a story page's rich body"

      MAX_BYTES = 8.megabytes
      MAX_DIMENSION = 1600

      argument :file, ::ApolloUploadServer::Upload, required: true,
        description: "The image file (PNG, JPEG, or WebP, max 8MB)"
      argument :story_page_id, ID, required: true, description: "Story page to attach the image to"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :url, String, null: true, description: "Hosted URL of the stored image"

      def resolve(file:, story_page_id:)
        story_page = require_owned!(:story_pages, "Story page", id: story_page_id)

        processed = ImageNormalizer.new(file, max_bytes: MAX_BYTES, max_dimension: MAX_DIMENSION, label: "Image").call
        blob = ActiveStorage::Blob.create_and_upload!(
          io: processed, filename: "story.webp", content_type: "image/webp"
        )
        story_page.description_images.attach(blob)
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
