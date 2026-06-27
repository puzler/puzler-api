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
      field :create_user_theme, mutation: ::Mutations::Users::CreateUserTheme,
        description: "Create a saved theme for the current user"
      field :delete_account, mutation: ::Mutations::Users::DeleteAccount,
        description: "Permanently delete the current user's account"
      field :delete_user_theme, mutation: ::Mutations::Users::DeleteUserTheme,
        description: "Delete one of the current user's saved themes"
      field :disconnect_oauth_provider, mutation: ::Mutations::Users::DisconnectOauthProvider,
        description: "Remove a linked OAuth provider"
      field :prepare_oauth_connect, mutation: ::Mutations::Users::PrepareOauthConnect,
        description: "Get a URL to start connecting an OAuth provider"
      field :remove_avatar, mutation: ::Mutations::Users::RemoveAvatar,
        description: "Remove the current user's uploaded avatar"
      field :update_onboarding, mutation: ::Mutations::Users::UpdateOnboarding,
        description: "Update the current user's onboarding/walkthrough state"
      field :update_player_prefs, mutation: ::Mutations::Users::UpdatePlayerPrefs,
        description: "Update the current user's solver-page preferences (settings and/or color palette)"
      field :update_profile, mutation: ::Mutations::Users::UpdateProfile,
        description: "Update the current user's profile information"
      field :update_profile_visibility, mutation: ::Mutations::Users::UpdateProfileVisibility,
        description: "Update the current user's public-profile visibility preferences"
      field :update_puzzle_preferences, mutation: ::Mutations::Users::UpdatePuzzlePreferences,
        description: "Update the current user's per-account puzzle defaults"
      field :update_theme_preferences, mutation: ::Mutations::Users::UpdateThemePreferences,
        description: "Update the current user's theme selection and the custom-styles gate"
      field :update_user_theme, mutation: ::Mutations::Users::UpdateUserTheme,
        description: "Update one of the current user's saved themes"
      field :upload_avatar, mutation: ::Mutations::Users::UploadAvatar,
        description: "Upload and set the current user's avatar"
    end
  end
end
