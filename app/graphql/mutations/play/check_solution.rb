module Mutations
  module Play
    class CheckSolution < Mutations::BaseMutation
      description "Check an in-progress board against the solution, returning a coarse " \
                  "result that never reveals which cells are wrong"

      argument :board, GraphQL::Types::JSON, required: true,
        description: "Filled cells keyed by coordinate (value = placed digit)"
      argument :puzzle_id, ID, required: true, description: "ID of the puzzle being checked"
      argument :share_token, String, required: false,
        description: "Share token, required to reach an unlisted puzzle"

      field :result, Types::Enums::CheckResultEnum, null: false,
        description: "SOLVED, CORRECT_SO_FAR, or INCORRECT"

      def resolve(puzzle_id:, board:, share_token: nil)
        puzzle = Puzzle.find_by(id: puzzle_id)
        return { result: "INCORRECT" } unless puzzle&.viewable_by?(current_user, share_token:)

        reject_during_competition!(puzzle.id)

        { result: SolutionGrader.result(puzzle, board) }
      end
    end
  end
end
