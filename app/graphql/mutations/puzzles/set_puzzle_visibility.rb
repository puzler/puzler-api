module Mutations
  module Puzzles
    class SetPuzzleVisibility < Mutations::BaseMutation
      description "Change a puzzle's access mode (private, unlisted, public, containers_only, " \
                  "or patrons_only for Patreon creators)"

      argument :id, ID, required: true, description: "ID of the puzzle"
      argument :visibility, Types::Enums::PuzzleVisibilityEnum, required: true,
        description: "private, unlisted, public, containers_only, or patrons_only (creators only)"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The updated puzzle"

      def resolve(id:, visibility:)
        puzzle = require_owned!(:puzzles, "Puzzle", id:)

        unless SelectableVisibilities.allowed?(current_user, visibility)
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
