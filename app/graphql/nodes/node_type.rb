# frozen_string_literal: true

module Nodes
  module NodeType
    include Interfaces::BaseInterface
    include GraphQL::Types::Relay::NodeBehaviors
  end
end
