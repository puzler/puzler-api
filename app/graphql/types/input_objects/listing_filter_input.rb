module Types
  module InputObjects
    # Shared filter/sort/paginate arguments for owned listings (My Puzzles,
    # Collections, Series) and the public archive. Fields not relevant to a
    # given entity are ignored by its resolver (e.g. constraintTypes on series,
    # or the archive-only facets on the My Puzzles lists).
    class ListingFilterInput < BaseInputObject
      description "Search, filter, sort, and pagination options for a listing"

      argument :author_username, String, required: false,
        description: "Filter to puzzles by this setter's username"
      argument :constraint_types, [ String ], required: false,
        description: "Filter to records using these constraint types (puzzles only)"
      argument :difficulties, [ Integer ], required: false,
        description: "Filter to puzzles whose effective difficulty rounds to any of these levels (1-5)"
      argument :featured, Boolean, required: false, description: "Only featured puzzles"
      argument :folder_id, ID, required: false,
        description: "Folder filter: 'all', 'unfiled', or a folder ID (puzzles and collections only)"
      argument :grid_sizes, [ String ], required: false,
        description: "Filter to puzzles of these grid sizes, each 'ROWSxCOLS' (e.g. '9x9')"
      argument :match_mode, Types::Enums::MatchModeEnum, required: false, default_value: "ANY",
        description: "Whether constraint filters match ANY or ALL of the selected types"
      argument :min_rating, Float, required: false, description: "Only puzzles with at least this average star rating"
      argument :my_status, Types::Enums::MyStatusEnum, required: false,
        description: "Filter by the current viewer's relationship (solved/unsolved/favorited/shared-with-me)"
      argument :page, Integer, required: false, default_value: 1, description: "Page number (1-based)"
      argument :per_page, Integer, required: false, default_value: 20, description: "Results per page"
      argument :search, String, required: false,
        description: "Free-text search across title, description, and author"
      argument :setter_tier, Types::Enums::SetterTierEnum, required: false,
        description: "Filter to puzzles by setters in this experience tier"
      argument :sort, Types::Enums::ListingSortEnum, required: false, default_value: "RECENT",
        description: "Sort order"
      argument :tags, [ String ], required: false, description: "Filter to puzzles with any of these tag slugs"
      argument :time_range, Types::Enums::TimeRangeEnum, required: false,
        description: "Filter by how recently the puzzle was published"
      argument :visibilities, [ String ], required: false,
        description: "Filter to any of these visibility buckets (e.g. PUBLIC, UNLISTED, or DRAFT for puzzles)"

      # Keyword args for OwnedListing.apply. Entity resolvers add the
      # entity-specific flags (constraints:, folders:, draft_bucket:, recent_by:,
      # viewer:).
      def to_listing_args
        {
          search:, constraint_types:, match_mode:, visibilities:, folder_id:, sort:, page:, per_page:,
          author_username:, time_range:, setter_tier:, difficulties:, tags:, min_rating:, my_status:, featured:, grid_sizes:
        }
      end
    end
  end
end
