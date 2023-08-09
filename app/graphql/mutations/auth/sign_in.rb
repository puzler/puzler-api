# frozen_string_literal: true

module Mutations
  module Auth
    class SignIn < AuthMutation
      argument :email, String, required: true, description: 'User Email'
      argument :password, String, required: true, description: 'User Password'

      description 'Sign in with email and password'
      authenticated false

      field :jwt, String, null: true, description: 'A Signed JWT for Authenticating the User'

      def resolve(email:, password:)
        user = User.find_by(email:)
        return error(paranoid_failure_message) unless user&.valid_password?(password)

        jwt_if_authticatable(user)
      end

      private

      def paranoid_failure_message
        I18n.t(
          'devise.failure.invalid',
          authentication_keys: 'email'
        )
      end
    end
  end
end
