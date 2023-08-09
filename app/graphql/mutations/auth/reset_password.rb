# frozen_string_literal: true

module Mutations
  module Auth
    class ResetPassword < AuthMutation
      argument :password,
               String,
               required: true,
               description: 'The new password to use'
      argument :token,
               String,
               required: true,
               description: 'Token sent to the User during a password reset request'

      description "Reset a User's password using a token sent to their email"
      authenticated false

      field :jwt, String, null: true, description: 'A Signed JWT used to authenticate the User'

      def resolve(token:, password:)
        user = User.reset_password_by_token(
          reset_password_token: token,
          password:
        )
        return errors_for(user) if user.errors.any?

        jwt_if_authticatable(user)
      end
    end
  end
end
