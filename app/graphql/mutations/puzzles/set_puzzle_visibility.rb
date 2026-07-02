module Mutations
  module Puzzles
    class SetPuzzleVisibility < Mutations::BaseMutation
      description "Change a puzzle's access mode (private, unlisted, public, or containers_only)"

      # The patron/subscriber tiers exist in the model but aren't selectable yet.
      SELECTABLE = %w[private unlisted public containers_only].freeze

      argument :id, ID, required: true, description: "ID of the puzzle"
      argument :visibility, Types::Enums::PuzzleVisibilityEnum, required: true,
        description: "private, unlisted, public, or containers_only"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The updated puzzle"

      def resolve(id:, visibility:)
        puzzle = require_owned!(:puzzles, "Puzzle", id:)

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
