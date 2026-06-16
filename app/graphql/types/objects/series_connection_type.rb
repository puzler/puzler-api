module Types
  module Objects
    # A page of series plus pagination metadata.
    class SeriesConnectionType < BaseObject
      description "A paginated page of series"

      field :nodes, [ SeriesType ], null: false, description: "Series on this page"
      field :page_info, PageInfoType, null: false, description: "Pagination metadata"

      def page_info = object
    end
  end
end
