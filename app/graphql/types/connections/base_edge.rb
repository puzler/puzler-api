# frozen_string_literal: true

module Types
  module Connections
    class BaseEdge < Types::Objects::BaseObject
      # add `node` and `cursor` fields, as well as `node_type(...)` override
      include GraphQL::Types::Relay::EdgeBehaviors
    end
  end
end
