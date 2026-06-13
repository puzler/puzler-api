module Mutations
  module Users
    class UploadAvatar < Mutations::BaseMutation
      description "Upload and set the current user's avatar (multipart file upload). " \
                  "The image is downscaled, EXIF-stripped, and stored as WebP."

      argument :file, ::ApolloUploadServer::Upload, required: true,
        description: "The image file (PNG, JPEG, or WebP, max 5MB)"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :user, Types::Objects::UserType, null: true,
        description: "The updated user"

      def resolve(file:)
        require_auth!

        processed = AvatarNormalizer.new(file).call
        current_user.avatar.attach(io: processed, filename: "avatar.webp", content_type: "image/webp")
        { user: current_user, errors: [] }
      rescue AvatarNormalizer::InvalidImage => e
        { user: nil, errors: [ e.message ] }
      end
    end
  end
end
