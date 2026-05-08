# frozen_string_literal: true

module Types
  module Unions
    class BaseUnion < GraphQL::Schema::Union
      edge_type_class(Types::Connections::BaseEdge)
      connection_type_class(Types::Connections::BaseConnection)
    end
  end
end
