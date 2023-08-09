# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    module ResolveWrapper
      def self.prepended(base)
        class << base
          attr_reader :auth_requirement unless method_defined?(:auth_requirement)
          def authenticated(yes_or_no)
            @auth_requirement = yes_or_no ? :authenticated : :not_authenticated
          end
        end
      end

      def resolve(...)
        case self.class.auth_requirement
        when :not_authenticated
          return error(I18n.t('devise.failure.already_authenticated')) if current_user.present?
        when :authenticated
          return error(I18n.t('devise.failure.not_authenticated')) if current_user.nil?
        end

        super(...)
      end
    end

    argument_class Arguments::BaseArgument
    field_class Fields::BaseField
    input_object_class InputObjects::BaseInputObject
    object_class BaseObject

    field :errors, [String], null: true, description: 'Error messages passed along with mutation response'
    field :success, Boolean, null: false, description: 'Flag marking if mutation was successful'

    def self.inherited(child)
      super(child)
      child.prepend(ResolveWrapper)
    end

    def errors_for(object)
      { success: false, errors: object.errors.full_messages }
    end

    def error(msg)
      { success: false, errors: [msg] }
    end

    def current_user
      context[:current_user]
    end
  end
end
