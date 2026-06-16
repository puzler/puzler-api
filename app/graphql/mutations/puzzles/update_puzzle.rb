module Mutations
  module Puzzles
    class UpdatePuzzle < Mutations::BaseMutation
      description "Update metadata, grid content, or solution for a draft puzzle"

      argument :attrs, Types::InputObjects::UpdatePuzzleAttrsInput, required: true,
        description: "Fields to update on the puzzle"
      argument :id, ID, required: true,
        description: "ID of the puzzle to update"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :puzzle, Types::Objects::PuzzleType, null: true,
        description: "The updated puzzle"

      def resolve(id:, attrs:)
        require_auth!
        puzzle = current_user.puzzles.find_by(id:)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        update_attrs = attrs.to_h.compact
        if update_attrs[:solution].present?
          update_attrs[:solution_hash] = SolutionHasher.hash(update_attrs[:solution])
        end

        if puzzle.update(update_attrs)
          # Author difficulty feeds the effective difficulty until community votes
          # take over, so re-resolve it whenever it might have changed.
          puzzle.recompute_difficulty! if update_attrs.key?(:author_difficulty)
          { puzzle:, errors: [] }
        else
          { puzzle: nil, errors: puzzle.errors.full_messages }
        end
      end
    end
  end
end
