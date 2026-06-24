module Types
  module InputObjects
    class UserThemeAttrsInput < BaseInputObject
      description "Editable fields of a saved theme"

      argument :appearance, GraphQL::Types::JSON, required: false,
        description: "Sparse chrome + grid token overrides"
      argument :base_preset_id, String, required: false,
        description: "Which built-in preset this theme derived from"
      argument :constraints, GraphQL::Types::JSON, required: false,
        description: "Sparse per-constraint style overrides"
      argument :name, String, required: false, description: "Theme name"
    end
  end
end
