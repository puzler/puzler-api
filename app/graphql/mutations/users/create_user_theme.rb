module Mutations
  module Users
    class CreateUserTheme < Mutations::BaseMutation
      description "Create a saved theme for the current user"

      argument :attrs, Types::InputObjects::UserThemeAttrsInput, required: true,
        description: "The theme's editable fields"
      argument :uid, String, required: true, description: "Client-generated stable theme id"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :user_theme, Types::Objects::UserThemeType, null: true, description: "The created theme"

      def resolve(uid:, attrs:)
        require_auth!
        data = attrs.to_h
        theme = current_user.user_themes.build(
          uid:,
          name: data[:name],
          base_preset_id: data[:base_preset_id] || "classic",
          appearance: data[:appearance] || {},
          constraints: data[:constraints] || {},
          position: (current_user.user_themes.maximum(:position) || -1) + 1,
        )
        if theme.save
          { user_theme: theme, errors: [] }
        else
          { user_theme: nil, errors: theme.errors.full_messages }
        end
      end
    end
  end
end
