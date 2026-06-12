module Mutations
  module Users
    class DeleteAccount < Mutations::BaseMutation
      description "Permanently delete the current user's account and all their data. " \
                  "Users with a password confirm with it; OAuth-only users type DELETE."

      argument :confirmation, String, required: false,
        description: 'Type "DELETE" to confirm (required for accounts without a password)'
      argument :current_password, String, required: false,
        description: "Current password (required when the account has one set)"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :success, Boolean, null: false,
        description: "Whether the account was deleted"

      def resolve(current_password: nil, confirmation: nil)
        require_auth!

        if current_user.password_set?
          unless current_user.valid_password?(current_password.to_s)
            return { success: false, errors: [ "Current password is incorrect" ] }
          end
        elsif confirmation != "DELETE"
          return { success: false, errors: [ 'Type "DELETE" to confirm' ] }
        end

        current_user.destroy!
        { success: true, errors: [] }
      end
    end
  end
end
