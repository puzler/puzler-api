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

      field :update_profile, mutation: ::Mutations::Users::UpdateProfile,
        description: "Update the current user's profile information"
    end
  end
end
