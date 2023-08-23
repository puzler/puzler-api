# frozen_string_literal: true

module Types
  class Puzzle < BaseType
    description 'A playable Sudoku Puzzle'
    field :author, String, null: true, description: 'The Puzzle Author'
    field :id, ID, null: true, description: 'The Puzzle ID'
    field :rules, String, null: true, description: 'Rules for the Puzzle'
    field :size, Integer, null: false, description: 'The Puzzle Size'
    field :solution, [Integer, { null: true }], null: true, description: 'The puzzle solution'
    field :title, String, null: true, description: 'The Puzzle Title'
    field :user, Types::User, null: true, description: 'The User who owns the Puzzle'

    field :visibility,
          Enums::Puzzles::Visibility,
          null: false,
          description: 'The visibility of the puzzle'

    field :cells,
          [[Types::Puzzles::GridCell]],
          null: false,
          description: 'Grid Cell data containing given digits and cell regions'

    field :global_constraints,
          Types::Puzzles::GlobalConstraints,
          null: false,
          description: 'Global Constraints for the Puzzle'

    field :local_constraints,
          Types::Puzzles::LocalConstraints,
          null: false,
          description: 'Local Constraints for the Puzzle'

    field :cosmetics,
          Types::Puzzles::CosmeticElements,
          null: false,
          description: 'Cosmetics for the Puzzle'

    def solution
      nil
    end
  end
end
