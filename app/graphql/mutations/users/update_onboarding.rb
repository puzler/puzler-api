module Mutations
  module Users
    class UpdateOnboarding < Mutations::BaseMutation
      description "Update the current user's onboarding/walkthrough state"

      argument :onboarding_disabled, Boolean, required: false,
        description: "Whether guided walkthroughs are turned off"
      argument :onboarding_seen, GraphQL::Types::JSON, required: false,
        description: "Map of tour keys the user has completed"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :user, Types::Objects::UserType, null: true,
        description: "The updated user"

      def resolve(onboarding_seen: nil, onboarding_disabled: nil)
        require_auth!
        attrs = { onboarding_seen:, onboarding_disabled: }.compact
        if attrs.empty? || current_user.update(attrs)
          { user: current_user, errors: [] }
        else
          { user: nil, errors: current_user.errors.full_messages }
        end
      end
    end
  end
end
