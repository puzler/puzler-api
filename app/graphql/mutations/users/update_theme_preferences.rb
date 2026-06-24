module Mutations
  module Users
    class UpdateThemePreferences < Mutations::BaseMutation
      description "Update the current user's theme selection and the custom-styles gate"

      argument :active_theme_id, String, required: false,
        description: "Built-in preset id or a saved theme's stable id"
      argument :enable_custom_styles, Boolean, required: false,
        description: "Whether the user's custom grid/constraint styling is applied"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :user, Types::Objects::UserType, null: true, description: "The updated user"

      def resolve(active_theme_id: nil, enable_custom_styles: nil)
        require_auth!
        attrs = { active_theme_id:, enable_custom_styles: }.compact
        if attrs.empty? || current_user.update(attrs)
          { user: current_user, errors: [] }
        else
          { user: nil, errors: current_user.errors.full_messages }
        end
      end
    end
  end
end
