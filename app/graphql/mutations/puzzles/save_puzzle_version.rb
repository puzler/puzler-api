module Mutations
  module Puzzles
    class SavePuzzleVersion < Mutations::BaseMutation
      description "Save the current editor state as a new immutable version of a puzzle"

      argument :definition, GraphQL::Types::JSON, required: true,
        description: "Full serialized puzzle definition (serializePuzzle output, minus solution)"
      argument :label, String, required: false,
        description: "Optional name for this version (defaults to v{n})"
      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle to snapshot"
      argument :solution, GraphQL::Types::JSON, required: false,
        description: "Solution grid; required before this version can be published"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :version, Types::Objects::PuzzleVersionType, null: true,
        description: "The newly created version"

      def resolve(puzzle_id:, definition:, solution: nil, label: nil)
        require_auth!
        puzzle = current_user.puzzles.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        version = puzzle.versions.build(
          definition:,
          label: label.presence,
          solution: solution || {},
          solution_hash: SolutionHasher.hash(solution),
          constraint_types: ConstraintTypeExtractor.extract(definition)
        )

        if version.save
          { version:, errors: [] }
        else
          { version: nil, errors: version.errors.full_messages }
        end
      end
    end
  end
end
