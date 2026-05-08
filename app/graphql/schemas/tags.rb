module Schemas
  module Tags
    module Queries
      include Types::Interfaces::BaseInterface
      description "Tag queries"
      graphql_name "TagQueries"

      field :tags, [ Types::Objects::TagType ], null: false,
        description: "All available tags, ordered alphabetically"

      def tags
        Tag.all.order(:name)
      end
    end
  end
end
