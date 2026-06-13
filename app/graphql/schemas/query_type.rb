# frozen_string_literal: true

# Composition layer — no fields are defined here directly.
# Each `implements` line attaches a domain schema module (a GraphQL interface)
# that owns a group of related query fields. To add a new category of
# queries, create a Queries module in a new schemas/<category>.rb file
# and add an `implements` line below.
module Schemas
  class QueryType < Types::Objects::BaseObject
    description "Root query type — all queries are composed from domain-specific schema modules"

    implements Users::Queries
    implements Puzzles::Queries
    implements Collections::Queries
    implements Tags::Queries
  end
end
