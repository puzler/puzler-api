module Mutations
  module Play
    class RevokePlaySession < Mutations::BaseMutation
      description "Stop sharing a play session: revoke its tokens and remove collaborators (owner only)"

      argument :puzzle_play_id, ID, required: true,
        description: "The play session to stop sharing"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle_play, Types::Objects::PuzzlePlayType, null: true,
        description: "The play session that was unshared"

      def resolve(puzzle_play_id:)
        require_auth!
        play = PuzzlePlay.find_by(id: puzzle_play_id)
        raise GraphQL::ExecutionError, "Play session not found" unless play
        raise GraphQL::ExecutionError, "Not authorized" unless play.user_id == current_user.id

        play.share_tokens.where(revoked_at: nil).update_all(revoked_at: Time.current)
        play.participants.destroy_all
        # Nudge any kicked clients; their next save/subscribe now fails authorization.
        trigger_progress_updated(play)

        { puzzle_play: play, errors: [] }
      end
    end
  end
end
