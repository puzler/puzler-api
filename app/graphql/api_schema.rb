# frozen_string_literal: true

# Root schema — wires together the three operation root types and enables
# Dataloader (batch-loading) and ActionCable (WebSocket subscriptions).
#
# Query and Mutation root types live in app/graphql/schemas/ and are composed
# from per-domain schema modules rather than defining fields directly here.
# See app/graphql/GRAPHQL.md for a full overview of the library structure.
class ApiSchema < GraphQL::Schema
  mutation(Schemas::MutationType)
  query(Schemas::QueryType)
  subscription(Types::Objects::SubscriptionType)

  use GraphQL::Dataloader
  use GraphQL::Subscriptions::ActionCableSubscriptions

  max_complexity(300)
  max_depth(15)
  max_query_string_tokens(5000)
  validate_max_errors(100)

  def self.unauthorized_object(error)
    raise GraphQL::ExecutionError, "Not authorized to access #{error.type.graphql_name}"
  end

  def self.unauthorized_field(error)
    raise GraphQL::ExecutionError, "Not authorized to access #{error.field.graphql_name} on #{error.type.graphql_name}"
  end
end
