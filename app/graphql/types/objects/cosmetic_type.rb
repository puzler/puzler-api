module Types
  module Objects
    class CosmeticType < BaseObject
      description "A visual decoration on a puzzle (cell color, line, shape, or text label)"

      field :cosmetic_type, String, null: false, description: "Cosmetic type identifier"
      field :data, GraphQL::Types::JSON, null: false, description: "Type-specific extra data"
      field :display_order, Integer, null: false, description: "Render order among cosmetics"
      field :id, ID, null: false, description: "Unique cosmetic ID"
      field :position, GraphQL::Types::JSON, null: false,
        description: "Position descriptor — cell, edge, or corner with associated cell keys"
      field :style, GraphQL::Types::JSON, null: false, description: "Visual style properties"
    end
  end
end
