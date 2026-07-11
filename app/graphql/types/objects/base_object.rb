# frozen_string_literal: true

module Types
  module Objects
    class BaseObject < GraphQL::Schema::Object
      include CompetitionGuard

      edge_type_class(Types::Connections::BaseEdge)
      connection_type_class(Types::Connections::BaseConnection)
      field_class Types::Fields::BaseField
    end
  end
end
