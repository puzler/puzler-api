module Mutations
  module Play
    class SubmitSolutionCode < Mutations::BaseMutation
      description "Claim a solve by entering the setter's solution code (for puzzles solved off-site)"

      argument :code, String, required: true,
        description: "The solution code to check against the setter's code"
      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle being claimed"
      argument :share_token, String, required: false,
        description: "Share token, required to reach an unlisted puzzle"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :recorded, Boolean, null: false,
        description: "True when this solve was newly recorded (false for the author or a repeat solve)"
      field :solve_message, String, null: true,
        description: "The author's custom solve message, present only on a correct non-author solve"
      field :solved, Boolean, null: false,
        description: "True when the code matched the puzzle's solution code"

      def resolve(puzzle_id:, code:, share_token: nil)
        actor = current_actor
        raise GraphQL::ExecutionError, "Identity required" unless actor

        puzzle = Puzzle.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle&.viewable_by?(current_user, share_token:)

        version = puzzle.published_version
        if version&.solution_code.blank?
          return { solved: false, recorded: false, solve_message: nil,
                   errors: [ "This puzzle does not accept a solution code" ] }
        end

        solved = version.solution_code_matches?(code)
        outcome = solved ? puzzle.record_solve!(actor) : :unsolved
        message = solved && outcome != :author ? version.solve_message.presence : nil

        { solved:, recorded: outcome == :recorded, solve_message: message, errors: [] }
      end
    end
  end
end
