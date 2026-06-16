module Types
  module Objects
    # Offset-pagination metadata for a listing page. (Distinct from the Relay
    # cursor PageInfo in Types::Connections; our listings page by number.)
    class PageInfoType < BaseObject
      description "Pagination metadata for an offset-paginated listing"

      field :has_next_page, Boolean, null: false, description: "Whether a page follows this one"
      field :has_previous_page, Boolean, null: false, description: "Whether a page precedes this one"
      field :page, Integer, null: false, description: "Current page number (1-based)"
      field :per_page, Integer, null: false, description: "Results per page"
      field :total_count, Integer, null: false, description: "Total matching records across all pages"
      field :total_pages, Integer, null: false, description: "Total number of pages"
    end
  end
end
