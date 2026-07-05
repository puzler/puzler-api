module Types
  module Objects
    class PuzzleVersionType < BaseObject
      description "An immutable saved snapshot of a puzzle"

      field :constraint_types, [ String ], null: false,
        description: "Constraint-type tags present in this version, for archive filtering"
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false,
        description: "When this version was saved"
      field :definition, GraphQL::Types::JSON, null: false,
        description: "Full serialized puzzle definition (serializePuzzle output, minus solution)"
      field :display_name, String, null: false,
        description: "Author label, or the 'v{version_number}' fallback"
      field :fog_cell_hashes, GraphQL::Types::JSON, null: true,
        description: "Per-cell solution hashes for client-side fog clearing; present only when the puzzle uses Fog of War"
      field :id, ID, null: false, description: "Unique version ID"
      field :is_published, Boolean, null: false,
        description: "Whether this is the puzzle's currently published version"
      field :label, String, null: true, description: "Optional author-provided name"
      field :solution, GraphQL::Types::JSON, null: true,
        description: "Solution grid for this version; only visible to the author"
      field :solution_code, String, null: true,
        description: "Setter's off-site solution code; only visible to the author"
      field :solution_hash, String, null: true,
        description: "SHA-256 of the solution, used for client-side completion detection"
      field :solve_message, String, null: true,
        description: "Custom solve message; only visible to the author (revealed to solvers on a correct solve)"
      field :version_number, Integer, null: false, description: "Sequential per-puzzle version number"

      def is_published
        object.puzzle.published_version_id == object.id
      end

      # Play-safe by design: each hash only confirms a digit the solver already
      # placed, which the fog mechanic reveals through play anyway.
      def fog_cell_hashes
        return nil unless object.fog_enabled?

        FogCellHasher.hashes(object.solution, object.solution_hash)
      end

      def solution
        return object.solution if author_or_admin?

        nil
      end

      def solution_code
        return object.solution_code if author_or_admin?

        nil
      end

      def solve_message
        return object.solve_message if author_or_admin?

        nil
      end

      private

      def author_or_admin?
        context[:current_user]&.id == object.puzzle.author_id || context[:current_user]&.admin?
      end
    end
  end
end
