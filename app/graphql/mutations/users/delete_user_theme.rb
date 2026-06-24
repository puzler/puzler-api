module Mutations
  module Users
    class DeleteUserTheme < Mutations::BaseMutation
      description "Delete one of the current user's saved themes"

      argument :uid, String, required: true, description: "Stable id of the theme to delete"

      field :deleted_id, ID, null: true, description: "The deleted theme's id, or null if not found"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(uid:)
        require_auth!
        theme = current_user.user_themes.find_by(uid:)
        return { deleted_id: nil, errors: [ "Theme not found" ] } unless theme

        theme.destroy
        { deleted_id: uid, errors: [] }
      end
    end
  end
end
