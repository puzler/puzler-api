module Mutations
  module Play
    class SubmitSolution < Mutations::BaseMutation
      description "Submit a completed solution for server-side validation"

      argument :cell_state, GraphQL::Types::JSON, required: true,
        description: "Final cell state keyed by cell coordinate"
      argument :puzzle_play_id, ID, required: true,
        description: "ID of the play session being submitted"
      argument :time_elapsed_seconds, Integer, required: true,
        description: "Total seconds taken to solve the puzzle"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :solved, Boolean, null: false,
        description: "True when the submitted solution is correct"

      def resolve(puzzle_play_id:, cell_state:, time_elapsed_seconds:)
        play = PuzzlePlay.includes(:puzzle).find_by(id: puzzle_play_id)
        raise GraphQL::ExecutionError, "Play session not found" unless play
        raise GraphQL::ExecutionError, "Not authorized" unless play.accessible_by?(current_actor)

        submitted_values = cell_state.transform_values { |v| v.is_a?(Hash) ? v["value"] : v }
                                     .reject { |_, v| v.nil? }
        solution = play.puzzle.solution

        solved = solution.present? && submitted_values == solution.transform_keys(&:to_s)

        if solved
          play.update!(
            is_solved: true,
            completed_at: Time.current,
            time_elapsed_seconds:,
            cell_state:
          )
          play.puzzle.increment!(:solve_count)
          play.puzzle.refresh_container_aggregates!
        end

        { solved:, errors: [] }
      end
    end
  end
end
