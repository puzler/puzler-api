# frozen_string_literal: true

module Schemas
  class PuzlerQueries < BaseObject
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    implements Schemas::Auth::AuthQueries
  end
end
