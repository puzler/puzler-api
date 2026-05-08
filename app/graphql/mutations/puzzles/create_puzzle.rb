module Mutations
  module Puzzles
    class CreatePuzzle < Mutations::BaseMutation
      description "Create a new draft puzzle"

      argument :description, String, required: false,
        description: "Optional description or story text"
      argument :grid_cols, Integer, required: false, default_value: 9,
        description: "Number of grid columns (default 9)"
      argument :grid_rows, Integer, required: false, default_value: 9,
        description: "Number of grid rows (default 9)"
      argument :title, String, required: true,
        description: "Puzzle title"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true,
        description: "The newly created puzzle"

      def resolve(title:, description: nil, grid_rows: 9, grid_cols: 9)
        require_auth!
        puzzle = current_user.puzzles.build(title:, description:, grid_rows:, grid_cols:)
        if puzzle.save
          { puzzle:, errors: [] }
        else
          { puzzle: nil, errors: puzzle.errors.full_messages }
        end
      end
    end
  end
end
