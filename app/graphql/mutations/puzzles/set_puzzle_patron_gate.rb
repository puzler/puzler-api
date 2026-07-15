module Mutations
  module Puzzles
    class SetPuzzlePatronGate < Mutations::BaseMutation
      include Mutations::AppliesPatronGate

      description "Configure who qualifies for a patrons-only puzzle; null gate resets to the " \
                  "default (any paying patron)"

      argument :gate, Types::InputObjects::PatronGateInput, required: false,
        description: "The gate configuration; omit/null to clear back to the default gate"
      argument :id, ID, required: true, description: "ID of the puzzle"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true, description: "The updated puzzle"

      def resolve(id:, gate: nil)
        puzzle = require_owned!(:puzzles, "Puzzle", id:)

        errors = apply_patron_gate(puzzle, gate)
        errors.empty? ? { puzzle:, errors: [] } : { puzzle: nil, errors: }
      end
    end
  end
end
