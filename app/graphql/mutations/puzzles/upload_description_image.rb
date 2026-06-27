module Mutations
  module Puzzles
    # Upload an image to embed in a puzzle's rich description (multipart). The
    # image is downscaled, EXIF-stripped, and stored as WebP, then attached to the
    # puzzle so it can be cleaned up later. Returns the hosted URL the editor
    # inserts as <img src> — which the sanitizer then accepts (host matches).
    class UploadDescriptionImage < Mutations::BaseMutation
      description "Upload and store an image for a puzzle's rich description"

      MAX_BYTES = 8.megabytes
      MAX_DIMENSION = 1600

      argument :file, ::ApolloUploadServer::Upload, required: true,
        description: "The image file (PNG, JPEG, or WebP, max 8MB)"
      argument :puzzle_id, ID, required: true, description: "Puzzle to attach the image to"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :url, String, null: true, description: "Hosted URL of the stored image"

      def resolve(file:, puzzle_id:)
        require_auth!
        puzzle = current_user.puzzles.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        processed = ImageNormalizer.new(file, max_bytes: MAX_BYTES, max_dimension: MAX_DIMENSION, label: "Image").call
        blob = ActiveStorage::Blob.create_and_upload!(
          io: processed, filename: "description.webp", content_type: "image/webp"
        )
        puzzle.description_images.attach(blob)
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
