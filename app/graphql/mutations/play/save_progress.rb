module Mutations
  module Play
    class SaveProgress < Mutations::BaseMutation
      description "Persist the current cell state and elapsed time for an in-progress play session"

      argument :cell_state, GraphQL::Types::JSON, required: true,
        description: "Current cell state keyed by cell coordinate"
      argument :progress_state, GraphQL::Types::JSON, required: false,
        description: "Full session state (undo/redo history, timer, selection, input mode)"
      argument :puzzle_play_id, ID, required: true,
        description: "ID of the play session to update"
      argument :time_elapsed_seconds, Integer, required: true,
        description: "Total seconds elapsed since the session started"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :puzzle_play, Types::Objects::PuzzlePlayType, null: true,
        description: "The updated play session"

      def resolve(puzzle_play_id:, cell_state:, time_elapsed_seconds:, progress_state: {})
        play = PuzzlePlay.find_by(id: puzzle_play_id)
        raise GraphQL::ExecutionError, "Play session not found" unless play
        raise GraphQL::ExecutionError, "Not authorized" unless play.accessible_by?(current_actor)

        # Never let a late autosave (e.g. from another tab) clobber a finished
        # solve; the completed board is already persisted.
        return { puzzle_play: play, errors: [ "Session already solved" ] } if play.is_solved

        if play.update(cell_state:, time_elapsed_seconds:, progress_state:)
          trigger_progress_updated(play)
          { puzzle_play: play, errors: [] }
        else
          { puzzle_play: nil, errors: play.errors.full_messages }
        end
      end
    end
  end
end
