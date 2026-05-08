module Mutations
  module Play
    class SaveProgress < Mutations::BaseMutation
      description "Persist the current cell state and elapsed time for an in-progress play session"

      argument :cell_state, GraphQL::Types::JSON, required: true,
        description: "Current cell state keyed by cell coordinate"
      argument :puzzle_play_id, ID, required: true,
        description: "ID of the play session to update"
      argument :time_elapsed_seconds, Integer, required: true,
        description: "Total seconds elapsed since the session started"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :puzzle_play, Types::Objects::PuzzlePlayType, null: true,
        description: "The updated play session"

      def resolve(puzzle_play_id:, cell_state:, time_elapsed_seconds:)
        play = PuzzlePlay.find_by(id: puzzle_play_id)
        raise GraphQL::ExecutionError, "Play session not found" unless play
        raise GraphQL::ExecutionError, "Not authorized" if play.user_id && play.user_id != current_user&.id

        if play.update(cell_state:, time_elapsed_seconds:)
          { puzzle_play: play, errors: [] }
        else
          { puzzle_play: nil, errors: play.errors.full_messages }
        end
      end
    end
  end
end
