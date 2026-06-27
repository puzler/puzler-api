module Types
  module Objects
    class UserType < BaseObject
      description "A registered user"

      field :active_theme_id, String, null: true,
        description: "The user's selected theme: a built-in preset id or a saved theme id (only visible to the user themselves)"
      field :activity, [ Types::Objects::ProfileActivityType ], null: false,
        description: "Recent public activity (published puzzles, reviews written, solves); empty unless visible to the viewer" do
        argument :limit, Integer, required: false, default_value: 30, description: "Max items to return"
      end
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
      field :favorited_puzzles, Types::Objects::PuzzleConnectionType, null: false, connection: false,
        description: "Puzzles this user has favorited; empty unless visible to the viewer" do
        argument :filter, Types::InputObjects::ListingFilterInput, required: false,
          description: "Search, filter, sort, and pagination options"
      end
      field :id, ID, null: false, description: "Unique user ID"
      field :oauth_connections, [ OauthIdentityType ], null: true,
        description: "Linked OAuth providers (only visible to the user themselves)"
      field :onboarding_disabled, Boolean, null: true,
        description: "Whether the user has turned off guided walkthroughs (only visible to the user themselves)"
      field :onboarding_seen, GraphQL::Types::JSON, null: true,
        description: "Map of tour keys the user has completed (only visible to the user themselves)"
      field :password_set, Boolean, null: true,
        description: "Whether the user has set a password they know (only visible to the user themselves)"
      field :player_settings, GraphQL::Types::JSON, null: true,
        description: "The user's solver-page settings (only visible to the user themselves)"
      field :profile_stats, Types::Objects::ProfileStatsType, null: true,
        description: "Aggregate public metrics; null unless visible to the viewer"
      field :profile_visibility, Types::Objects::ProfileVisibilityType, null: false, method: :itself,
        description: "Owner-controlled visibility preferences for this profile (public, so the client knows which sections to render)"
      field :public_collection_count, Integer, null: false,
        description: "Number of this user's publicly visible collections"
      field :public_series_count, Integer, null: false,
        description: "Number of this user's publicly visible series"
      field :puzzle_count, Integer, null: false,
        description: "Number of published or featured puzzles by this user"
      field :puzzles, [ PuzzleType ], null: false, description: "Puzzles created by this user" do
        argument :status, Types::Enums::PuzzleStatusEnum, required: false, description: "Filter by puzzle status"
      end
      field :reviews_received, Types::Objects::CommentConnectionType, null: false, connection: false,
        description: "Reviews left on this user's public puzzles (always public)" do
        argument :page, Integer, required: false, default_value: 1, description: "Page number (1-based)"
        argument :per_page, Integer, required: false, default_value: 20, description: "Results per page"
      end
      field :role, Types::Enums::UserRoleEnum, null: false, description: "Account role: user or admin"
      field :setter_score, Float, null: false,
        description: "Raw setter score behind the tier (volume blended with recency-weighted rating)"
      field :setter_tier, Types::Enums::SetterTierEnum, null: false,
        description: "Setter experience tier: new, rising, or experienced"
      field :solve_count, Integer, null: false, description: "Number of puzzles this user has completed"
      field :solved_puzzles, Types::Objects::SolvedPuzzleConnectionType, null: false, connection: false,
        description: "Puzzles this user has solved; empty unless their solve-history disclosure reveals them" do
        argument :filter, Types::InputObjects::ListingFilterInput, required: false,
          description: "Search, filter, sort, and pagination options"
      end
      field :subscribed_series, Types::Objects::SeriesConnectionType, null: false, connection: false,
        description: "Series this user is subscribed to; empty unless visible to the viewer" do
        argument :filter, Types::InputObjects::ListingFilterInput, required: false,
          description: "Search, filter, sort, and pagination options"
      end
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

      def onboarding_seen
        object.onboarding_seen if viewer_is_self?
      end

      def onboarding_disabled
        object.onboarding_disabled if viewer_is_self?
      end

      def puzzles(status: nil)
        scope = object.puzzles
        status ? scope.where(status: status) : scope.publicly_visible
      end

      def puzzle_count
        object.puzzles.publicly_visible.count
      end

      # Always-public counts so the profile can decide which setter tabs to show
      # even when the owner has hidden their aggregate stats panel.
      def public_collection_count
        object.collections.publicly_visible.count
      end

      def public_series_count
        object.series.publicly_visible.count
      end

      def solve_count
        object.puzzle_plays.completed.count
      end

      # Aggregate stats, gated by show_stats (owner always sees). Resolved from
      # the User itself by ProfileStatsType.
      def profile_stats
        return nil unless viewer_is_self? || object.show_stats

        object
      end

      # Solved puzzles, with the FOUR-level gate. hidden/count expose no list;
      # puzzles/detailed (or the owner) do. At "detailed" each item also carries
      # the rating and review THIS user left, batch-loaded to avoid N+1.
      def solved_puzzles(filter: nil)
        return OwnedListing.empty_page unless viewer_is_self? || object.solve_history_at_least?(:puzzles)

        solved_ids = object.puzzle_plays.completed.select(:puzzle_id)
        scope = Puzzle.publicly_visible.where(id: solved_ids).includes(:author, :tags, :constraints)
        page = OwnedListing.apply(
          scope, **(filter ? filter.to_listing_args : {}),
          constraints: true, recent_by: :published_at, viewer: context[:current_user]
        )

        detailed = viewer_is_self? || object.solve_history_at_least?(:detailed)
        ratings = reviews = nil
        if detailed
          ids = page.nodes.map(&:id)
          ratings = object.ratings.where(puzzle_id: ids).index_by(&:puzzle_id)
          reviews = object.comments.top_level.where(puzzle_id: ids).group_by(&:puzzle_id)
        end

        nodes = page.nodes.map do |puzzle|
          {
            puzzle:,
            owner_rating: detailed ? ratings[puzzle.id] : nil,
            owner_review: detailed ? reviews[puzzle.id]&.first : nil
          }
        end
        OwnedListing::Page.new(nodes:, total_count: page.total_count, page: page.page, per_page: page.per_page)
      end

      # Reviews left on this user's public puzzles. Always public (no toggle).
      def reviews_received(page: 1, per_page: 20)
        scope = Comment.top_level
                       .where(puzzle_id: object.puzzles.publicly_visible.select(:id))
                       .by_newest
                       .includes(:user, puzzle: :author)
        OwnedListing.paginate(scope, page:, per_page:)
      end

      # Puzzles this user has favorited, gated by show_favorites (owner always sees).
      def favorited_puzzles(filter: nil)
        return OwnedListing.empty_page unless viewer_is_self? || object.show_favorites

        scope = Puzzle.publicly_visible
                      .where(id: object.favorites.select(:puzzle_id))
                      .includes(:author, :tags, :constraints)
        OwnedListing.apply(
          scope, **(filter ? filter.to_listing_args : {}),
          constraints: true, recent_by: :published_at, viewer: context[:current_user]
        )
      end

      # Public series this user subscribes to, gated by show_subscriptions.
      def subscribed_series(filter: nil)
        return OwnedListing.empty_page unless viewer_is_self? || object.show_subscriptions

        scope = ::Series.publicly_visible
                        .where(id: object.series_subscriptions.select(:series_id))
                        .includes(:author)
        OwnedListing.apply(scope, **(filter ? filter.to_listing_args : {}))
      end

      # A merged, time-sorted recent activity feed, gated by show_activity. SOLVE
      # items additionally honor the solve-history gate so activity can't leak
      # solves the user has hidden. Capped, not paginated.
      def activity(limit: 30)
        return [] unless viewer_is_self? || object.show_activity

        include_solves = viewer_is_self? || object.solve_history_at_least?(:puzzles)
        public_ids = Puzzle.publicly_visible.select(:id)

        events = object.puzzles.publicly_visible.order(published_at: :desc).limit(limit).map do |puzzle|
          { kind: "PUBLISHED_PUZZLE", occurred_at: puzzle.published_at, puzzle:, comment: nil }
        end
        events += object.comments.top_level.where(puzzle_id: public_ids).by_newest.limit(limit)
                        .includes(puzzle: :author).map do |comment|
          { kind: "REVIEW_WRITTEN", occurred_at: comment.created_at, puzzle: comment.puzzle, comment: }
        end
        if include_solves
          events += object.puzzle_plays.completed.where(puzzle_id: public_ids)
                          .order(completed_at: :desc).limit(limit).includes(puzzle: :author).map do |play|
            { kind: "SOLVE", occurred_at: play.completed_at || play.updated_at, puzzle: play.puzzle, comment: nil }
          end
        end
        events.select { |event| event[:occurred_at] }.sort_by { |event| event[:occurred_at] }.reverse.first(limit)
      end

      private

      def viewer_is_self?
        object == context[:current_user]
      end
    end
  end
end
