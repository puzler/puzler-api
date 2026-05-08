module Types
  module Objects
    class ConstraintType < BaseObject
      description "A logical constraint on a puzzle (killer cage, thermometer, etc.)"

      field :constraint_type, String, null: false, description: "Constraint type identifier"
      field :data, GraphQL::Types::JSON, null: false, description: "Constraint-specific configuration data"
      field :display_order, Integer, null: false, description: "Render order among constraints"
      field :id, ID, null: false, description: "Unique constraint ID"
    end
  end
end
