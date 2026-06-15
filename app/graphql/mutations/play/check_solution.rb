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

        solution = puzzle.published_version&.solution
        return { result: "INCORRECT" } if solution.blank?

        sol = solution.transform_keys(&:to_s).transform_values(&:to_i)
        # Only consider actually-filled cells; coerce to ints so JSON strings and
        # numbers compare equal.
        submitted = board.transform_keys(&:to_s)
                         .transform_values(&:to_i)
                         .reject { |_, v| v.zero? }

        # A filled cell that disagrees with the solution (wrong digit, or a digit
        # where the solution is blank) makes the whole board incorrect.
        return { result: "INCORRECT" } unless submitted.all? { |k, v| sol[k] == v }

        complete = sol.all? { |k, v| submitted[k] == v }
        { result: complete ? "SOLVED" : "CORRECT_SO_FAR" }
      end
    end
  end
end
