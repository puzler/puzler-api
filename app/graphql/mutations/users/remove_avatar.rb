module Mutations
  module Users
    class RemoveAvatar < Mutations::BaseMutation
      description "Remove the current user's uploaded avatar (falls back to any OAuth profile image)"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :user, Types::Objects::UserType, null: true,
        description: "The updated user"

      def resolve
        require_auth!

        current_user.avatar.purge if current_user.avatar.attached?
        { user: current_user, errors: [] }
      end
    end
  end
end
