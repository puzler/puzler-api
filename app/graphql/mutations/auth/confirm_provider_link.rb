# frozen_string_literal: true

module Mutations
  module Auth
    class ConfirmProviderLink < AuthMutation
      argument :token,
               String,
               required: true,
               description: 'The token attached to the link sent in the confirmation email'

      field :jwt, String, null: true, description: 'A Signed JWT for authenticating a user'

      description 'Confirm linking an OAuth provider to a User'

      def resolve(token:)
        auth_link = UserOAuthProvider.confirm_by_token(token)
        return error('Request could not be found, or it may have expired.') if auth_link.nil?
        return errors_for(auth_link) if auth_link.errors.any?

        user = auth_link.user
        jwt = user.generate_jwt if current_user.nil?

        {
          success: true,
          jwt:
        }
      end
    end
  end
end
