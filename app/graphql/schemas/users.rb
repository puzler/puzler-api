module Schemas
  module Users
    module Queries
      include Types::Interfaces::BaseInterface
      description "User profile queries"
      graphql_name "UserQueries"

      field :me, Types::Objects::UserType, null: true,
        description: "The currently authenticated user, or null if unauthenticated"
      field :user, Types::Objects::UserType, null: true,
        description: "Find a user by username" do
        argument :username, String, required: true, description: "Username to look up"
      end

      def me
        context[:current_user]
      end

      def user(username:)
        User.find_by(username:)
      end
    end

    module Mutations
      include Types::Interfaces::BaseInterface
      description "User account mutations"
      graphql_name "UserMutations"

      field :change_password, mutation: ::Mutations::Users::ChangePassword,
        description: "Set or change the current user's password"
      field :delete_account, mutation: ::Mutations::Users::DeleteAccount,
        description: "Permanently delete the current user's account"
      field :disconnect_oauth_provider, mutation: ::Mutations::Users::DisconnectOauthProvider,
        description: "Remove a linked OAuth provider"
      field :prepare_oauth_connect, mutation: ::Mutations::Users::PrepareOauthConnect,
        description: "Get a URL to start connecting an OAuth provider"
      field :remove_avatar, mutation: ::Mutations::Users::RemoveAvatar,
        description: "Remove the current user's uploaded avatar"
      field :update_profile, mutation: ::Mutations::Users::UpdateProfile,
        description: "Update the current user's profile information"
      field :upload_avatar, mutation: ::Mutations::Users::UploadAvatar,
        description: "Upload and set the current user's avatar"
    end
  end
end
