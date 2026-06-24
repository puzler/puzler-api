module Mutations
  module Users
    class UpdateUserTheme < Mutations::BaseMutation
      description "Update one of the current user's saved themes"

      argument :attrs, Types::InputObjects::UserThemeAttrsInput, required: true,
        description: "The fields to change (only those present are updated)"
      argument :uid, String, required: true, description: "Stable id of the theme to update"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :user_theme, Types::Objects::UserThemeType, null: true, description: "The updated theme"

      def resolve(uid:, attrs:)
        require_auth!
        theme = current_user.user_themes.find_by(uid:)
        return { user_theme: nil, errors: [ "Theme not found" ] } unless theme

        changes = attrs.to_h.slice(:name, :base_preset_id, :appearance, :constraints).compact
        if changes.empty? || theme.update(changes)
          { user_theme: theme, errors: [] }
        else
          { user_theme: nil, errors: theme.errors.full_messages }
        end
      end
    end
  end
end
