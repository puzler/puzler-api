module Mutations
  module Users
    # Update the current user's per-account puzzle defaults. Partial updates are
    # fine — omitted fields are dropped (mirrors UpdateProfileVisibility).
    class UpdatePuzzlePreferences < Mutations::BaseMutation
      description "Update the current user's per-account puzzle defaults"

      argument :attrs, Types::InputObjects::PuzzlePreferencesInput, required: true,
        description: "Puzzle defaults to update"

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
