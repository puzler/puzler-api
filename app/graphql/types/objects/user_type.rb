module Types
  module Objects
    class UserType < BaseObject
      description "A registered user"

      field :active_theme_id, String, null: true,
        description: "The user's selected theme: a built-in preset id or a saved theme id (only visible to the user themselves)"
      field :avatar_url, String, null: true, method: :resolved_avatar_url, description: "Profile picture URL"
      field :bio, String, null: true, description: "Short biography shown on the user's profile"
      field :color_palette, GraphQL::Types::JSON, null: true,
        description: "The user's customized cell-coloring palette (only visible to the user themselves)"
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this account was created"
      field :display_name, String, null: false,
        description: "Free-form name shown to others (not unique)"
      field :email, String, null: true, description: "User's email address (only visible to the user themselves)"
      field :enable_custom_styles, Boolean, null: true,
        description: "Whether the user's custom grid/constraint styling is applied (only visible to the user themselves)"
      field :id, ID, null: false, description: "Unique user ID"
      field :oauth_connections, [ OauthIdentityType ], null: true,
        description: "Linked OAuth providers (only visible to the user themselves)"
      field :password_set, Boolean, null: true,
        description: "Whether the user has set a password they know (only visible to the user themselves)"
      field :player_settings, GraphQL::Types::JSON, null: true,
        description: "The user's solver-page settings (only visible to the user themselves)"
      field :puzzle_count, Integer, null: false,
        description: "Number of published or featured puzzles by this user"
      field :puzzles, [ PuzzleType ], null: false, description: "Puzzles created by this user" do
        argument :status, Types::Enums::PuzzleStatusEnum, required: false, description: "Filter by puzzle status"
      end
      field :role, Types::Enums::UserRoleEnum, null: false, description: "Account role: user or admin"
      field :setter_score, Float, null: false,
        description: "Raw setter score behind the tier (volume blended with recency-weighted rating)"
      field :setter_tier, Types::Enums::SetterTierEnum, null: false,
        description: "Setter experience tier: new, rising, or experienced"
      field :solve_count, Integer, null: false, description: "Number of puzzles this user has completed"
      field :user_themes, [ Types::Objects::UserThemeType ], null: true,
        description: "The user's saved themes, in sort order (only visible to the user themselves)"
      field :username, String, null: false, description: "Unique handle used in profile URLs and lookups"

      def email
        object.email if viewer_is_self?
      end

      def oauth_connections
        object.oauth_identities if viewer_is_self?
      end

      def player_settings
        object.player_settings if viewer_is_self?
      end

      def color_palette
        object.color_palette if viewer_is_self?
      end

      def active_theme_id
        object.active_theme_id if viewer_is_self?
      end

      def enable_custom_styles
        object.enable_custom_styles if viewer_is_self?
      end

      def user_themes
        object.user_themes.order(:position, :id) if viewer_is_self?
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
