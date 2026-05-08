module Schemas
  module Puzzles
    module Queries
      include Types::Interfaces::BaseInterface
      description "Puzzle archive queries"
      graphql_name "PuzzleQueries"

      field :my_puzzles, [ Types::Objects::PuzzleType ], null: false,
        description: "All puzzles belonging to the current user" do
        argument :status, String, required: false, description: "Filter by status (draft, published, featured)"
      end

      field :puzzle, Types::Objects::PuzzleType, null: true,
        description: "Find a puzzle by ID" do
        argument :id, ID, required: true, description: "Puzzle ID to look up"
      end

      field :puzzles, [ Types::Objects::PuzzleType ], null: false,
        description: "Browse the published puzzle archive with optional filters" do
        argument :author_username, String, required: false, description: "Filter by setter username"
        argument :difficulty, String, required: false,
          description: "Filter by difficulty band: easy, medium, hard, or expert"
        argument :page, Integer, required: false, default_value: 1, description: "Page number (1-based)"
        argument :per_page, Integer, required: false, default_value: 20, description: "Results per page"
        argument :sort, String, required: false, default_value: "newest",
          description: "Sort order: newest, rating, or popular"
        argument :status, String, required: false, description: "Filter by status"
        argument :tags, [ String ], required: false, description: "Filter by tag slugs (any match)"
      end

      def puzzle(id:)
        record = Puzzle.find_by(id:)
        return nil unless record
        return record if record.author_id == context[:current_user]&.id
        return nil unless record.published? || record.featured?

        record
      end

      def puzzles(page:, per_page:, tags: nil, difficulty: nil, author_username: nil, status: nil, sort: "newest")
        scope = Puzzle.published_or_featured.includes(:author, :tags, :constraints)

        scope = scope.joins(:tags).where(tags: { slug: tags }) if tags.present?
        scope = scope.where("avg_difficulty BETWEEN ? AND ?", difficulty_range(difficulty)) if difficulty.present?
        scope = scope.joins(:author).where(users: { username: author_username }) if author_username.present?

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
      field :publish_puzzle, mutation: ::Mutations::Puzzles::PublishPuzzle,
        description: "Publish a draft puzzle"
      field :update_puzzle, mutation: ::Mutations::Puzzles::UpdatePuzzle,
        description: "Update metadata or content on a puzzle"
    end
  end
end
