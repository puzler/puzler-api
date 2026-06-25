module Mutations
  module Play
    class StartPlay < Mutations::BaseMutation
      description "Start or resume a play session for a published puzzle"

      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle to play"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :puzzle_play, Types::Objects::PuzzlePlayType, null: true,
        description: "The new or existing unsolved play session"

      def resolve(puzzle_id:)
        puzzle = Puzzle.publicly_visible.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        # Server-side progress is for signed-in users only; guests persist to
        # localStorage, so we never create anonymous play rows. Returning a nil
        # play tells the client to fall back to its local snapshot.
        return { puzzle_play: nil, errors: [] } unless current_user

        play = current_user.puzzle_plays.in_progress.find_or_create_by(puzzle:) do |p|
          p.started_at = Time.current
        end

        { puzzle_play: play, errors: [] }
      end
    end
  end
end
