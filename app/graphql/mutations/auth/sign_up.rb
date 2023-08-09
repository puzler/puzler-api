# frozen_string_literal: true

module Mutations
  module Auth
    class SignUp < AuthMutation
      argument :email, String, required: true, description: 'Email used to sign in'
      argument :password, String, required: true, description: 'Password used to sign in'

      description 'Sign Up as a User'
      authenticated false

      field :jwt, String, null: true, description: 'A Signed JWT for Authenticating the User'

      def resolve(email:, password:)
        user = User.create(
          email:,
          password:
        )
        return errors_for(user) if user.errors.any?

        jwt_if_authticatable(user)
      end
    end
  end
end
