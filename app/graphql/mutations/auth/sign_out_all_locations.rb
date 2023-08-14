# frozen_string_literal: true

module Mutations
  module Auth
    class SignOutAllLocations < AuthMutation
      description 'Signs a User out of all locations by cycling their current JWT salt'
      authenticated true

      def resolve
        current_user.regenerate_jwt_salt
        return errors_for(current_user) if current_user.errors.any?

        { success: true }
      end
    end
  end
end
