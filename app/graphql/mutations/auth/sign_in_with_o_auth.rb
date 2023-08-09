# frozen_string_literal: true

module Mutations
  module Auth
    class SignInWithOAuth < AuthMutation
      argument :code, String, required: true, description: 'The Authentication Code provided by the OAuth provider'
      argument :provider_name, String, required: true, description: 'The OAuth provider'

      description 'Verifies an OAuth Code and returns a Signed JWT to authenticate the User'
      authenticated false

      field :jwt,
            String,
            null: true,
            description: 'A Signed JWT used to authenticate a User'

      def resolve(code:, provider_name:)
        user = get_user_from_code(
          code,
          provider_name
        )
        return oauth_failure(user[:error], provider_name) if user.is_a? Hash
        return oauth_failure('a user with that email already exists', provider_name) unless user&.errors&.empty?

        jwt_if_authticatable(user)
      end

      private

      def oauth_failure(reason, kind)
        error(
          I18n.t(
            'devise.omniauth_callbacks.failure',
            reason:,
            kind:
          )
        )
      end

      def get_user_data(code, provider)
        token = provider.get_token(code)[:access_token]
        return if token.nil?

        data = provider.get_user(token)
        return if data[:id].nil? || data[:email].nil?

        data
      end

      def get_user_from_code(code, provider_name)
        provider = valid_providers[provider_name]&.new
        return { error: 'Unknown Provider' } if provider.nil?

        user_data = get_user_data(code, provider)
        return { error: 'OAuth Authentication Failed' } if user_data.nil?

        User.from_oauth(user_data, provider_name)
      end

      def valid_providers
        @valid_providers ||= {
          facebook: AuthProviders::Facebook
        }.with_indifferent_access
      end
    end
  end
end
