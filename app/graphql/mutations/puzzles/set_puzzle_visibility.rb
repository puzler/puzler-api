module Mutations
  module Puzzles
    class SetPuzzleVisibility < Mutations::BaseMutation
      description "Change a puzzle's access mode (private, unlisted, or public)"

      # The patron/subscriber tiers exist in the model but aren't selectable yet.
      SELECTABLE = %w[private unlisted public].freeze

      argument :id, ID, required: true, description: "ID of the puzzle"
      argument :visibility, String, required: true, description: "private, unlisted, or public"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The updated puzzle"

      def resolve(id:, visibility:)
        require_auth!
        puzzle = current_user.puzzles.find_by(id:)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        unless SELECTABLE.include?(visibility)
          return { puzzle: nil, errors: [ "Unsupported visibility: #{visibility}" ] }
        end

        if puzzle.update(visibility:)
          { puzzle:, errors: [] }
        else
          { puzzle: nil, errors: puzzle.errors.full_messages }
        end
      end
    end
  end
end
