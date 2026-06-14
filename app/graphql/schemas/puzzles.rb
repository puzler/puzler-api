module Schemas
  module Puzzles
    module Queries
      include Types::Interfaces::BaseInterface
      description "Puzzle archive queries"
      graphql_name "PuzzleQueries"

      field :my_puzzles, [ Types::Objects::PuzzleType ], null: false,
        description: "All puzzles belonging to the current user" do
        argument :status, Types::Enums::PuzzleStatusEnum, required: false, description: "Filter by status (draft or published)"
      end

      field :puzzle, Types::Objects::PuzzleType, null: true,
        description: "Find a puzzle by ID, if the current user is allowed to see it" do
        argument :id, ID, required: true, description: "Puzzle ID to look up"
      end

      field :puzzle_by_token, Types::Objects::PuzzleType, null: true,
        description: "Find a puzzle by its share token (used for unlisted/solve links)" do
        argument :token, String, required: true, description: "The puzzle's share token"
      end

      field :puzzle_version, Types::Objects::PuzzleVersionType, null: true,
        description: "Fetch a single version's full content for editing or restore (author only)" do
        argument :id, ID, required: true, description: "Version ID to look up"
      end

      field :puzzles, [ Types::Objects::PuzzleType ], null: false,
        description: "Browse the published puzzle archive with optional filters" do
        argument :author_username, String, required: false, description: "Filter by setter username"
        argument :constraint_types, [ String ], required: false,
          description: "Filter to puzzles using any of these constraint types"
        argument :difficulty, String, required: false,
          description: "Filter by difficulty band: easy, medium, hard, or expert"
        argument :page, Integer, required: false, default_value: 1, description: "Page number (1-based)"
        argument :per_page, Integer, required: false, default_value: 20, description: "Results per page"
        argument :sort, String, required: false, default_value: "newest",
          description: "Sort order: newest, rating, or popular"
        argument :status, Types::Enums::PuzzleStatusEnum, required: false, description: "Filter by status"
        argument :tags, [ String ], required: false, description: "Filter by tag slugs (any match)"
      end

      def puzzle(id:)
        record = Puzzle.find_by(id:)
        return nil unless record&.viewable_by?(context[:current_user])

        record
      end

      def puzzle_by_token(token:)
        record = Puzzle.find_by(share_token: token)
        return nil unless record&.viewable_by?(context[:current_user], share_token: token)

        record
      end

      def puzzles(page:, per_page:, tags: nil, difficulty: nil, author_username: nil,
                  constraint_types: nil, status: nil, sort: "newest")
        scope = Puzzle.publicly_visible.includes(:author, :tags, :constraints)

        scope = scope.joins(:tags).where(tags: { slug: tags }) if tags.present?
        scope = scope.where("avg_difficulty BETWEEN ? AND ?", difficulty_range(difficulty)) if difficulty.present?
        scope = scope.joins(:author).where(users: { username: author_username }) if author_username.present?
        if constraint_types.present?
          scope = scope.where("puzzles.constraint_types && ARRAY[?]::varchar[]", constraint_types)
        end

        scope = case sort
        when "rating" then scope.by_rating
        when "popular" then scope.by_popularity
        else scope.by_newest
        end

        scope.offset((page - 1) * per_page).limit(per_page)
      end

      def my_puzzles(status: nil)
        raise GraphQL::ExecutionError, "Authentication required" unless context[:current_user]

        scope = context[:current_user].puzzles
        status ? scope.where(status:) : scope
      end

      def puzzle_version(id:)
        user = context[:current_user]
        return nil unless user

        PuzzleVersion.joins(:puzzle).find_by(id:, puzzles: { author_id: user.id })
      end

      private

      def difficulty_range(difficulty)
        case difficulty
        when "easy" then [ 0, 1.5 ]
        when "medium" then [ 1.5, 2.5 ]
        when "hard" then [ 2.5, 3.5 ]
        when "expert" then [ 3.5, 4.0 ]
        else [ 0, 4.0 ]
        end
      end
    end

    module Mutations
      include Types::Interfaces::BaseInterface
      description "Mutations for creating and managing puzzles"
      graphql_name "PuzzleMutations"

      field :create_puzzle, mutation: ::Mutations::Puzzles::CreatePuzzle,
        description: "Create a new draft puzzle"
      field :delete_puzzle, mutation: ::Mutations::Puzzles::DeletePuzzle,
        description: "Permanently delete a puzzle"
      field :delete_puzzle_version, mutation: ::Mutations::Puzzles::DeletePuzzleVersion,
        description: "Delete a saved puzzle version"
      field :grant_puzzle_access, mutation: ::Mutations::Puzzles::GrantPuzzleAccess,
        description: "Grant a user access to a puzzle by username"
      field :publish_puzzle_version, mutation: ::Mutations::Puzzles::PublishPuzzleVersion,
        description: "Publish a specific version as the live puzzle"
      field :revoke_puzzle_access, mutation: ::Mutations::Puzzles::RevokePuzzleAccess,
        description: "Revoke a user's access to a puzzle"
      field :save_puzzle_version, mutation: ::Mutations::Puzzles::SavePuzzleVersion,
        description: "Save the editor state as a new immutable version"
      field :set_puzzle_visibility, mutation: ::Mutations::Puzzles::SetPuzzleVisibility,
        description: "Change a puzzle's access mode"
      field :unpublish_puzzle, mutation: ::Mutations::Puzzles::UnpublishPuzzle,
        description: "Return a published puzzle to draft"
      field :update_puzzle, mutation: ::Mutations::Puzzles::UpdatePuzzle,
        description: "Update metadata or content on a puzzle"
      field :update_puzzle_version_label, mutation: ::Mutations::Puzzles::UpdatePuzzleVersionLabel,
        description: "Rename a saved puzzle version"
    end
  end
end
