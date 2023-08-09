# frozen_string_literal: true

module Mutations
  module Auth
    class SignOutAllLocations < AuthMutation
      description 'Signs a User out of all locations by cycling their current JWT salt'
      authenticated true

      def resolve
        return errors_for(current_user) unless current_user.cycle_jwt_salt

        { success: true }
      end
    end
  end
end
