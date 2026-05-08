# frozen_string_literal: true

module Types
  module Interfaces
    module NodeType
      include Types::Interfaces::BaseInterface
      description "An object with a globally unique ID"
      include GraphQL::Types::Relay::NodeBehaviors
    end
  end
end
