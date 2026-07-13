module Types
  module InputObjects
    class UpdatePuzzleAttrsInput < BaseInputObject
      description "Fields that can be updated on a puzzle"

      argument :author_difficulty, Integer, required: false,
        description: "Setter's chosen difficulty from 1 (gentlest) to 5 (hardest)"
      argument :box_layout, GraphQL::Types::JSON, required: false,
        description: "Custom box region definitions; null means standard 3×3 boxes"
      argument :description, String, required: false,
        description: "Optional description or story text"
      argument :given_digits, GraphQL::Types::JSON, required: false,
        description: "Pre-filled clue digits keyed by cell coordinate (r0c0: 5)"
      argument :grid_cols, Integer, required: false,
        description: "Number of columns in the grid"
      argument :grid_rows, Integer, required: false,
        description: "Number of rows in the grid"
      argument :ruleset, GraphQL::Types::JSON, required: false,
        description: "Boolean variant flags (diagonals, knights_move, etc.)"
      argument :title, String, required: false,
        description: "Puzzle title"
    end
  end
end
