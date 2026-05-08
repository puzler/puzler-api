# frozen_string_literal: true

module Types
  module Interfaces
    module BaseInterface
      include GraphQL::Schema::Interface
      edge_type_class(Types::Connections::BaseEdge)
      connection_type_class(Types::Connections::BaseConnection)

      field_class Types::Fields::BaseField
    end
  end
end
