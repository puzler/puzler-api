# frozen_string_literal: true

module Mutations
  module Auth
    class SignInWithOAuth < BaseMutation
      argument :code, String, required: true
      argument :provider_name, String, required: true

      field :jwt, String, null: true

      def resolve(code:, provider_name:)
        return error('Already Logged In') if current_user.present?

        user = get_user_from_code(
          code,
          provider_name
        )
        return error(user[:error]) if user.is_a? Hash
        return error('Could not create User') if user.nil? || user.errors.any?

        {
          success: true,
          jwt: user.generate_jwt
        }
      end

      private

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
