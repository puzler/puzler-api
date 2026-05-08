module Schemas
  module Constraints
    module Mutations
      include Types::Interfaces::BaseInterface
      description "Mutations for managing puzzle constraints"
      graphql_name "ConstraintMutations"

      field :delete_constraint, mutation: ::Mutations::Constraints::DeleteConstraint,
        description: "Delete a constraint from a puzzle"
      field :upsert_constraint, mutation: ::Mutations::Constraints::UpsertConstraint,
        description: "Create or update a constraint on a puzzle"
    end
  end
end
