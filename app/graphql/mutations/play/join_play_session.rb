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
        require_actor!
        actor = current_actor
        share = PuzzlePlayShareToken.find_by(token:)
        raise GraphQL::ExecutionError, "Invalid share link" unless share

        play = share.puzzle_play
        # Already the owner or a participant -> idempotent re-entry (e.g. the deep
        # link reloading after the modal's paste-flow already joined).
        return { puzzle_play: play, errors: [] } if play.accessible_by?(actor)

        raise GraphQL::ExecutionError, "You've been removed from this session" if play.blocked?(actor)
        raise GraphQL::ExecutionError, "This share link was revoked" if share.revoked_at

        if share.single_use
          # Atomic claim so two simultaneous joins (user or guest) can't both consume it.
          consume = actor.user? ? { consumed_by_id: actor.user_id } : { consumed_by_guest_token: actor.guest_token }
          claimed = PuzzlePlayShareToken.where(id: share.id, consumed_by_id: nil, consumed_by_guest_token: nil)
            .update_all(**consume, consumed_at: Time.current)
          raise GraphQL::ExecutionError, "This share link has already been used" if claimed.zero?
        end

        play.participants.create!(added_via_token: share, **actor.participant_attrs)
        { puzzle_play: play, errors: [] }
      end
    end
  end
end
