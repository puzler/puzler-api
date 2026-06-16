module Types
  module Objects
    # A page of puzzles plus pagination metadata. Resolved from an
    # OwnedListing::Page struct, which responds to all PageInfoType fields.
    class PuzzleConnectionType < BaseObject
      description "A paginated page of puzzles"

      field :nodes, [ PuzzleType ], null: false, description: "Puzzles on this page"
      field :page_info, PageInfoType, null: false, description: "Pagination metadata"

      def page_info = object
    end
  end
end
