module Schemas
  module Puzzles
    module Queries
      include Types::Interfaces::BaseInterface
      description "Puzzle archive queries"
      graphql_name "PuzzleQueries"

      field :my_puzzles, Types::Objects::PuzzleConnectionType, null: false, connection: false,
        description: "A page of puzzles belonging to the current user, with search/filter/sort" do
        argument :filter, Types::InputObjects::ListingFilterInput, required: false,
          description: "Search, filter, sort, and pagination options"
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

      field :puzzles, Types::Objects::PuzzleConnectionType, null: false, connection: false,
        description: "Browse the published puzzle archive with search/filter/sort/pagination" do
        argument :filter, Types::InputObjects::ListingFilterInput, required: false,
          description: "Search, filter, sort, and pagination options"
      end

      field :puzzle_grid_sizes, [ Types::Objects::GridSizeType ], null: false,
        description: "Distinct grid sizes present in the published archive, with counts, for the size facet"

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

      def puzzles(filter: nil)
        scope = Puzzle.publicly_visible.includes(:author, :tags, :constraints)
        args = filter ? filter.to_listing_args : {}
        OwnedListing.apply(
          scope, **args,
          constraints: true, recent_by: :published_at, viewer: context[:current_user]
        )
      end

      def puzzle_grid_sizes
        Puzzle.publicly_visible
              .group(:grid_rows, :grid_cols).order("count_all DESC").count
              .map { |(rows, cols), count| { rows:, cols:, count: } }
      end

      def my_puzzles(filter: nil, status: nil)
        raise GraphQL::ExecutionError, "Authentication required" unless context[:current_user]

        scope = context[:current_user].puzzles.includes(:author, :folder)
        scope = scope.where(status:) if status
        args = filter ? filter.to_listing_args : {}
        OwnedListing.apply(scope, **args, constraints: true, folders: true, draft_bucket: true)
      end

      def puzzle_version(id:)
        user = context[:current_user]
        return nil unless user

        PuzzleVersion.joins(:puzzle).find_by(id:, puzzles: { author_id: user.id })
      end
    end

    module Mutations
      include Types::Interfaces::BaseInterface
      description "Mutations for creating and managing puzzles"
      graphql_name "PuzzleMutations"

      field :configure_puzzle_page, mutation: ::Mutations::Puzzles::ConfigurePuzzlePage,
        description: "Save a puzzle's publish-page settings (comment gating and SudokuPad links)"
      field :create_puzzle, mutation: ::Mutations::Puzzles::CreatePuzzle,
        description: "Create a new draft puzzle"
      field :delete_puzzle, mutation: ::Mutations::Puzzles::DeletePuzzle,
        description: "Permanently delete a puzzle"
      field :delete_puzzle_version, mutation: ::Mutations::Puzzles::DeletePuzzleVersion,
        description: "Delete a saved puzzle version"
      field :export_sudokupad_link, mutation: ::Mutations::Puzzles::ExportSudokupadLink,
        description: "Build a short SudokuPad link from a Puzler definition"
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
      field :update_page_description, mutation: ::Mutations::Puzzles::UpdatePageDescription,
        description: "Save the sanitized rich description for a puzzle's public page"
      field :update_puzzle, mutation: ::Mutations::Puzzles::UpdatePuzzle,
        description: "Update metadata or content on a puzzle"
      field :update_puzzle_version_label, mutation: ::Mutations::Puzzles::UpdatePuzzleVersionLabel,
        description: "Rename a saved puzzle version"
      field :upload_description_image, mutation: ::Mutations::Puzzles::UploadDescriptionImage,
        description: "Upload an image for a puzzle's rich description"
    end
  end
end
