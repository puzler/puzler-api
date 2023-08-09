# frozen_string_literal: true

module Mutations
  module Auth
    class SignIn < BaseMutation
      argument :email, String, required: true, description: 'User Email'
      argument :password, String, required: true, description: 'User Password'

      description 'Sign in with email and password'

      field :jwt, String, null: true, description: 'A Signed JWT for Authenticating the User'

      def resolve(email:, password:)
        return error(I18n.t('devise.failure.already_authenticated')) if current_user.present?

        user = User.find_by(email:)
        return error(paranoid_failure_message) unless user&.valid_password?(password)
        return { success: true, jwt: user.generate_jwt } if user.active_for_authentication?

        error(
          I18n.t("devise.failure.#{user.inactive_message}")
        )
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
