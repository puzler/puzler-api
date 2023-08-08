# frozen_string_literal: true

module Edges
  class BaseEdge < BaseObject
    include GraphQL::Types::Relay::EdgeBehaviors
  end
end
