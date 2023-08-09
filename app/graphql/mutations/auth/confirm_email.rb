# frozen_string_literal: true

module Mutations
  module Auth
    class ConfirmEmail < AuthMutation
      argument :token,
               String,
               required: true,
               description: 'The token attatched to the link sent in the confirmation email'

      field :jwt, String, null: true, description: 'A Signed JWT for authenticating a user'

      description "Confirm a User's email with a token sent to their email"
      authenticated false

      def resolve(token:)
        user = User.confirm_by_token(token)
        return errors_for(user) if user.errors.any?

        jwt_if_authticatable(user)
      end
    end
  end
end
