module Types
  module InputObjects
    class CosmeticAttrsInput < BaseInputObject
      description "Attributes for creating or updating a cosmetic"

      argument :cosmetic_type, String, required: true,
        description: "Cosmetic type identifier (line, cell_color, shape, text)"
      # No default_value here: a {} default on a JSON scalar can't be rendered
      # back to an SDL literal, which breaks introspection round-trips
      # (graphql-codegen). The resolver applies the {} fallback instead.
      argument :data, GraphQL::Types::JSON, required: false,
        description: "Type-specific extra data (e.g. path for lines, shapeType for shapes)"
      argument :display_order, Integer, required: false,
        description: "Render order among cosmetics on this puzzle"
      argument :position, GraphQL::Types::JSON, required: true,
        description: "Position descriptor — cell, edge, or corner with associated cell keys"
      argument :style, GraphQL::Types::JSON, required: true,
        description: "Visual style properties (color, opacity, strokeWidth, etc.)"
    end
  end
end
