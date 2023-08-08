# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Arguments::BaseArgument
    field_class Fields::BaseField
    input_object_class InputObjects::BaseInputObject
    object_class BaseObject

    field :error, String, null: true, description: 'Error message passed along with mutation response'
    field :success, Boolean, null: false, description: 'Flag marking if mutation was successful'

    def error(msg)
      { success: false, error: msg }
    end

    def current_user
      context[:current_user]
    end
  end
end
