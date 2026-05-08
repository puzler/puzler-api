module Schemas
  module Cosmetics
    module Mutations
      include Types::Interfaces::BaseInterface
      description "Mutations for managing puzzle cosmetics"
      graphql_name "CosmeticMutations"

      field :delete_cosmetic, mutation: ::Mutations::Cosmetics::DeleteCosmetic,
        description: "Delete a cosmetic from a puzzle"
      field :upsert_cosmetic, mutation: ::Mutations::Cosmetics::UpsertCosmetic,
        description: "Create or update a cosmetic on a puzzle"
    end
  end
end
