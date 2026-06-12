module Mutations
  module Users
    class ChangePassword < Mutations::BaseMutation
      description "Set or change the current user's password. Users who signed up " \
                  "via OAuth (passwordSet: false) set one without a current password; " \
                  "everyone else must supply their current password."

      argument :current_password, String, required: false,
        description: "Current password (required when the user already has one set)"
      argument :new_password, String, required: true,
        description: "The new password"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :token, String, null: true,
        description: "Fresh JWT — changing the password revokes all existing sessions"
      field :user, Types::Objects::UserType, null: true,
        description: "The updated user"

      def resolve(new_password:, current_password: nil)
        require_auth!

        if current_user.password_set? && !current_user.valid_password?(current_password.to_s)
          return { user: nil, token: nil, errors: [ "Current password is incorrect" ] }
        end

        if current_user.update(password: new_password)
          # The model rotated jti on the password write, revoking every
          # outstanding JWT — hand back a fresh one so this session survives.
          { user: current_user, token: current_user.generate_jwt, errors: [] }
        else
          { user: nil, token: nil, errors: current_user.errors.full_messages }
        end
      end
    end
  end
end
