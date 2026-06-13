# frozen_string_literal: true

# Composition layer — no fields are defined here directly.
# Each `implements` line attaches a domain schema module (a GraphQL interface)
# that owns a group of related mutation fields. To add a new category of
# mutations, create a Mutations module in a new schemas/<category>.rb file
# and add an `implements` line below.
module Schemas
  class MutationType < Types::Objects::BaseObject
    description "Root mutation type — all mutations are composed from domain-specific schema modules"

    implements Users::Mutations
    implements Puzzles::Mutations
    implements Collections::Mutations
    implements Constraints::Mutations
    implements Cosmetics::Mutations
    implements Social::Mutations
    implements Play::Mutations
  end
end
