# frozen_string_literal: true

module Schemas
  class PuzlerQueries < BaseObject
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    description 'The base Query Object'

    implements Schemas::Auth::AuthQueries
    implements Schemas::Puzzles::PuzzleQueries
  end
end
