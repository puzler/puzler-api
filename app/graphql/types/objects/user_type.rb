module Types
  module Objects
    class UserType < BaseObject
      description "A registered user"

      field :avatar_url, String, null: true, method: :resolved_avatar_url, description: "Profile picture URL"
      field :bio, String, null: true, description: "Short biography shown on the user's profile"
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this account was created"
      field :email, String, null: true, description: "User's email address (only visible to the user themselves)"
      field :id, ID, null: false, description: "Unique user ID"
      field :oauth_connections, [ OauthIdentityType ], null: true,
        description: "Linked OAuth providers (only visible to the user themselves)"
      field :password_set, Boolean, null: true,
        description: "Whether the user has set a password they know (only visible to the user themselves)"
      field :puzzle_count, Integer, null: false,
        description: "Number of published or featured puzzles by this user"
      field :puzzles, [ PuzzleType ], null: false, description: "Puzzles created by this user" do
        argument :status, String, required: false, description: "Filter by puzzle status"
      end
      field :role, String, null: false, description: "Account role: user or admin"
      field :solve_count, Integer, null: false, description: "Number of puzzles this user has completed"
      field :username, String, null: false, description: "Public display name"

      def email
        object.email if viewer_is_self?
      end

      def oauth_connections
        object.oauth_identities if viewer_is_self?
      end

      def password_set
        object.password_set if viewer_is_self?
      end

      def puzzles(status: nil)
        scope = object.puzzles
        status ? scope.where(status: status) : scope.publicly_visible
      end

      def puzzle_count
        object.puzzles.publicly_visible.count
      end

      def solve_count
        object.puzzle_plays.completed.count
      end

      private

      def viewer_is_self?
        object == context[:current_user]
      end
    end
  end
end
