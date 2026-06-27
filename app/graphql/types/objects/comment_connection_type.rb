module Types
  module Objects
    # A page of comments plus pagination metadata. Resolved from an
    # OwnedListing::Page struct, which responds to all PageInfoType fields.
    class CommentConnectionType < BaseObject
      description "A paginated page of comments"

      field :nodes, [ CommentType ], null: false, description: "Comments on this page"
      field :page_info, PageInfoType, null: false, description: "Pagination metadata"

      def page_info = object
    end
  end
end
