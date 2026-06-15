module Mutations
  module Users
    class UpdatePlayerPrefs < Mutations::BaseMutation
      description "Update the current user's solver-page preferences (settings and/or color palette)"

      argument :color_palette, GraphQL::Types::JSON, required: false,
        description: "The user's customized cell-coloring palette (colors + pages)"
      argument :player_settings, GraphQL::Types::JSON, required: false,
        description: "The user's solver-page settings toggles"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :user, Types::Objects::UserType, null: true,
        description: "The updated user"

      def resolve(player_settings: nil, color_palette: nil)
        require_auth!
        attrs = { player_settings:, color_palette: }.compact
        if attrs.empty? || current_user.update(attrs)
          { user: current_user, errors: [] }
        else
          { user: nil, errors: current_user.errors.full_messages }
        end
      end
    end
  end
end
