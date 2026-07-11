module Mutations
  module Play
    class SubmitSolution < Mutations::BaseMutation
      description "Submit a completed board for server-side validation and solve recording"

      argument :cell_state, GraphQL::Types::JSON, required: true,
        description: "Final cell state keyed by cell coordinate"
      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle being solved"
      argument :share_token, String, required: false,
        description: "Share token, required to reach an unlisted puzzle"
      argument :time_elapsed_seconds, Integer, required: true,
        description: "Total seconds taken to solve the puzzle"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :recorded, Boolean, null: false,
        description: "True when this solve was newly recorded (false for the author or a repeat solve)"
      field :solve_message, String, null: true,
        description: "The author's custom solve message, present only on a correct non-author solve"
      field :solved, Boolean, null: false,
        description: "True when the submitted board matches the solution"

      def resolve(puzzle_id:, cell_state:, time_elapsed_seconds:, share_token: nil)
        actor = current_actor
        raise GraphQL::ExecutionError, "Identity required" unless actor

        puzzle = Puzzle.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle&.viewable_by?(current_user, share_token:)

        reject_during_competition!(puzzle.id)

        solved = SolutionGrader.correct?(puzzle, cell_state)

        outcome = solved ? puzzle.record_solve!(actor, cell_state:, time_elapsed_seconds:) : :unsolved
        message = solved && outcome != :author ? puzzle.published_version&.solve_message.presence : nil

        { solved:, recorded: outcome == :recorded, solve_message: message, errors: [] }
      end
    end
  end
end
