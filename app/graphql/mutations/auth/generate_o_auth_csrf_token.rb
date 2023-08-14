# frozen_string_literal: true

module Mutations
  module Auth
    class GenerateOAuthCsrfToken < BaseMutation
      argument :client_token_id,
               String,
               required: true,
               description: 'Token Identifier from the client'

      field :csrf_token, String, null: false, description: 'Server CSRF Token for OAuth validation'

      description 'Generates a secure token that is stored with the client_token_id to verify a future oauth request'

      def resolve(client_token_id:)
        token = CsrfToken.create(
          client_token_id:,
          token_type: :oauth
        )
        return errors_for(token) if token.errors.any?

        { success: true, csrf_token: token.token }
      end
    end
  end
end
