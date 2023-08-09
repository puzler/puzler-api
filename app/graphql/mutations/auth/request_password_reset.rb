# frozen_string_literal: true

module Mutations
  module Auth
    class RequestPasswordReset < AuthMutation
      argument :email,
               String,
               required: true,
               description: 'The email of the User requesting a reset'

      description "Request an email used to reset a User's password"
      authenticated false

      def resolve(email:)
        user = User.find_by('LOWER(email) = ?', email.downcase)
        user&.send_reset_password_instructions

        { success: true }
      end
    end
  end
end
