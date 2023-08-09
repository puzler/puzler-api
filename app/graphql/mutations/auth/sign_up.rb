# frozen_string_literal: true

module Mutations
  module Auth
    class SignUp < BaseMutation
      argument :email, String, required: true, description: 'Email used to sign in'
      argument :password, String, required: true, description: 'Password used to sign in'
      argument :password_confirmation, String, required: true, description: 'Confirm Password'

      description 'Sign Up as a User'

      field :needs_confirm, Bool, null: true
      field :jwt, String, null: true

      def resolve(email:, password:, password_confirmation:)
        return error(I18n.t('devise.failure.already_authenticated')) if current_user.present?

        display_name = find_unused_display_name(email)

        user = User.create(
          email:,
          password:,
          password_confirmation:,
          display_name: display_name
        )
        return error(user.errors.full_messages.first) if user.errors.any?
        return { success: true, jwt: user.generate_jwt } if user.active_for_authentication?

        {
          success: true,
          jwt: user.generate_jwt
        }
      end

      private

      def find_unused_display_name(email)
        display_name = email.split('@').first
        return display_name unless User.exists?('LOWER(display_name) = ?', display_name.downcase)

        append_number = 1
        while User.exists?('LOWER(display_name) = ?', "#{display_name.downcase}#{append_number}")
          append_number += 1
        end

        "#{display_name}#{append_number}"
      end
    end
  end
end
