module Types
  module Objects
    # A page of solved puzzles plus pagination metadata. Resolved from an
    # OwnedListing::Page whose nodes are SolvedPuzzleType hashes.
    class SolvedPuzzleConnectionType < BaseObject
      description "A paginated page of solved puzzles"

      field :nodes, [ SolvedPuzzleType ], null: false, description: "Solved puzzles on this page"
      field :page_info, PageInfoType, null: false, description: "Pagination metadata"

      def page_info = object
    end
  end
end
