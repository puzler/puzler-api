# frozen_string_literal: true

module Connections
  class BaseConnection < BaseObject
    include GraphQL::Types::Relay::ConnectionBehaviors
  end
end
