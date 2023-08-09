# frozen_string_literal: true

module Mutations
  module Auth
    class AuthMutation < BaseMutation
      description 'The Base Mutation for Auth Schema'

      private

      def jwt_if_authticatable(user)
        return devise_failure(user.invalid_message) unless user.valid_for_authentication?
        return devise_failure(user.inactive_message) unless user.active_for_authentication?

        {
          success: true,
          jwt: user.generate_jwt
        }
      end

      def devise_failure(message)
        error(
          I18n.t(
            "devise.failure.#{message}"
          )
        )
      end
    end
  end
end
