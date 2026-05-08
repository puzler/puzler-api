# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::Arguments::BaseArgument
    field_class Types::Fields::BaseField
    input_object_class Types::InputObjects::BaseInputObject
    object_class Types::Objects::BaseObject

    private

    def current_user
      context[:current_user]
    end

    def require_auth!
      raise GraphQL::ExecutionError, "Authentication required" unless current_user
    end
  end
end
