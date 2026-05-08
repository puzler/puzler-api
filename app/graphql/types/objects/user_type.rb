module Types
  module Objects
    class UserType < BaseObject
      description "A registered user"

      field :avatar_url, String, null: true, description: "Profile picture URL"
      field :bio, String, null: true, description: "Short biography shown on the user's profile"
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this account was created"
      field :email, String, null: false, description: "User's email address"
      field :id, ID, null: false, description: "Unique user ID"
      field :puzzle_count, Integer, null: false,
        description: "Number of published or featured puzzles by this user"
      field :puzzles, [ PuzzleType ], null: false, description: "Puzzles created by this user" do
        argument :status, String, required: false, description: "Filter by puzzle status"
      end
      field :role, String, null: false, description: "Account role: user or admin"
      field :solve_count, Integer, null: false, description: "Number of puzzles this user has completed"
      field :username, String, null: false, description: "Public display name"

      def puzzles(status: nil)
        scope = object.puzzles
        status ? scope.where(status: status) : scope.published_or_featured
      end

      def puzzle_count
        object.puzzles.published_or_featured.count
      end

      def solve_count
        object.puzzle_plays.completed.count
      end
    end
  end
end
