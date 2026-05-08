module Types
  module InputObjects
    class ConstraintAttrsInput < BaseInputObject
      description "Attributes for creating or updating a constraint"

      argument :constraint_type, String, required: true,
        description: "Constraint type identifier (e.g. killer_cage, thermometer)"
      argument :data, GraphQL::Types::JSON, required: true,
        description: "Constraint-specific configuration data"
      argument :display_order, Integer, required: false,
        description: "Render order among constraints on this puzzle"
    end
  end
end
