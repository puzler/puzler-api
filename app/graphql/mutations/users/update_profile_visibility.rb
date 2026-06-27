module Mutations
  module Users
    # Update the owner-controlled visibility of the user's public profile. Kept
    # separate from UpdateProfile so the identity form (name/bio/avatar) and the
    # privacy form save independently. Partial updates are fine — omitted fields
    # are dropped, so toggling one preference leaves the rest untouched.
    class UpdateProfileVisibility < Mutations::BaseMutation
      description "Update the current user's public-profile visibility preferences"

      argument :attrs, Types::InputObjects::ProfileVisibilityInput, required: true,
        description: "Visibility preferences to update"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :user, Types::Objects::UserType, null: true, description: "The updated user"

      def resolve(attrs:)
        require_auth!
        update_attrs = attrs.to_h.compact
        if update_attrs.empty? || current_user.update(update_attrs)
          { user: current_user, errors: [] }
        else
          { user: nil, errors: current_user.errors.full_messages }
        end
      end
    end
  end
end
