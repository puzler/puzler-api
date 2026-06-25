module Mutations
  module Play
    class JoinPlaySession < Mutations::BaseMutation
      description "Join a shared play session via its share token; returns the shared play to load"

      argument :token, String, required: true,
        description: "The share token from the link or pasted by the joiner"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle_play, Types::Objects::PuzzlePlayType, null: true,
        description: "The shared play session to load"

      def resolve(token:)
        require_auth!
        share = PuzzlePlayShareToken.find_by(token:)
        raise GraphQL::ExecutionError, "Invalid share link" unless share

        play = share.puzzle_play
        # Already the owner or a participant -> idempotent re-entry (e.g. the deep
        # link reloading after the modal's paste-flow already joined).
        return { puzzle_play: play, errors: [] } if play.accessible_by?(current_user)

        raise GraphQL::ExecutionError, "This share link was revoked" if share.revoked_at

        if share.single_use
          # Atomic claim so two simultaneous joins can't both consume it.
          claimed = PuzzlePlayShareToken.where(id: share.id, consumed_by_id: nil)
            .update_all(consumed_by_id: current_user.id, consumed_at: Time.current)
          raise GraphQL::ExecutionError, "This share link has already been used" if claimed.zero?
        end

        play.participants.create!(user: current_user, added_via_token: share)
        { puzzle_play: play, errors: [] }
      end
    end
  end
end
