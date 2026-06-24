module Types
  module Objects
    class UserThemeType < BaseObject
      description "A user's saved appearance + constraint theme"

      field :appearance, GraphQL::Types::JSON, null: false,
        description: "Sparse chrome + grid token overrides (frontend-owned shape)"
      field :base_preset_id, String, null: false,
        description: "Which built-in preset this theme derived from"
      field :constraints, GraphQL::Types::JSON, null: false,
        description: "Sparse per-constraint style overrides (frontend-owned shape)"
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this theme was created"
      field :id, ID, null: false, method: :uid,
        description: "Stable client-owned theme id (the selection id, shared across devices)"
      field :name, String, null: false, description: "Theme name shown in the picker"
      field :position, Integer, null: false, description: "Sort position among the user's themes"
      field :schema_version, Integer, null: false, description: "Theme data schema version"
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this theme was last edited"
    end
  end
end
