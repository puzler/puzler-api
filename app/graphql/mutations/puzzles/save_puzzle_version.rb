module Mutations
  module Puzzles
    class SavePuzzleVersion < Mutations::BaseMutation
      description "Save the current editor state as a new immutable version of a puzzle"

      argument :attrs, Types::InputObjects::PuzzleVersionAttrsInput, required: true,
        description: "Editor state to snapshot"
      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle to snapshot"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :version, Types::Objects::PuzzleVersionType, null: true,
        description: "The newly created version"

      def resolve(puzzle_id:, attrs:)
        require_auth!
        puzzle = current_user.puzzles.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        version = puzzle.versions.build(
          definition: attrs.definition,
          label: attrs.label.presence,
          solution: attrs.solution || {},
          solution_hash: SolutionHasher.hash(attrs.solution),
          solve_message: attrs.solve_message.presence,
          constraint_types: ConstraintTypeExtractor.extract(attrs.definition)
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
