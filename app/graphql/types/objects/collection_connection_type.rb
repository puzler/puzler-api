module Types
  module Objects
    # A page of collections plus pagination metadata.
    class CollectionConnectionType < BaseObject
      description "A paginated page of collections"

      field :nodes, [ CollectionType ], null: false, description: "Collections on this page"
      field :page_info, PageInfoType, null: false, description: "Pagination metadata"

      def page_info = object
    end
  end
end
