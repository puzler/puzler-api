module Mutations
  module Play
    class StartPlay < Mutations::BaseMutation
      description "Start or resume a play session for a published puzzle"

      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle to play"
      argument :share_token, String, required: false,
        description: "Share token, required to reach an unlisted puzzle"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :puzzle_play, Types::Objects::PuzzlePlayType, null: true,
        description: "The new or existing unsolved play session"

      def resolve(puzzle_id:, share_token: nil)
        puzzle = Puzzle.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle&.viewable_by?(current_user, share_token:)

        actor = current_actor
        return { puzzle_play: nil, errors: [] } unless actor

        play =
          if actor.user?
            actor.user.puzzle_plays.in_progress.find_or_create_by(puzzle:) { |p| p.started_at = Time.current }
          else
            # Guest: resume an already-promoted guest-hosted play; never create one
            # here (solo guests stay localStorage-only until they share to host).
            PuzzlePlay.guest_hosted.in_progress.find_by(puzzle:, guest_token: actor.guest_token)
          end

        { puzzle_play: play, errors: [] }
      end
    end
  end
end
