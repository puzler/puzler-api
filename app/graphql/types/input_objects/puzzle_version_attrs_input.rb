module Types
  module InputObjects
    class PuzzleVersionAttrsInput < BaseInputObject
      description "Editor state to snapshot as an immutable puzzle version"

      argument :definition, GraphQL::Types::JSON, required: true,
        description: "Full serialized puzzle definition (serializePuzzle output, minus solution)"
      argument :label, String, required: false,
        description: "Optional name for this version (defaults to v{n})"
      argument :solution, GraphQL::Types::JSON, required: false,
        description: "Solution grid; required before this version can be published"
      argument :solve_message, String, required: false,
        description: "Custom message shown on a correct solve (blank uses the default)"
    end
  end
end
