module Mutations
  module Users
    class UpdateProfile < Mutations::BaseMutation
      description "Update the current user's profile information"

      argument :avatar_url, String, required: false,
        description: "URL for the user's profile picture"
      argument :bio, String, required: false,
        description: "Short biography shown on the user's profile page"
      argument :display_name, String, required: false,
        description: "Free-form name shown to others (not unique)"
      argument :username, String, required: false,
        description: "Unique handle used in profile URLs and lookups"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :user, Types::Objects::UserType, null: true,
        description: "The updated user"

      def resolve(username: nil, display_name: nil, bio: nil, avatar_url: nil)
        require_auth!
        attrs = { username:, display_name:, bio:, avatar_url: }.compact
        if current_user.update(attrs)
          { user: current_user, errors: [] }
        else
          { user: nil, errors: current_user.errors.full_messages }
        end
      end
    end
  end
end
