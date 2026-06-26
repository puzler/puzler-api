module Mutations
  module Play
    class KickParticipant < Mutations::BaseMutation
      description "Remove a collaborator from a play session (host only), optionally blocking rejoin"

      argument :actor_id, String, required: true,
        description: "The participant's stamped identity, e.g. user:<id> or guest:<token>"
      argument :block, Boolean, required: false,
        description: "When true, also bar this identity from rejoining via a still-active link"
      argument :puzzle_play_id, ID, required: true,
        description: "The play session to remove them from"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :success, Boolean, null: false, description: "Whether the participant was removed"

      def resolve(puzzle_play_id:, actor_id:, block: false)
        require_actor!
        play = PuzzlePlay.find_by(id: puzzle_play_id)
        raise GraphQL::ExecutionError, "Play session not found" unless play
        raise GraphQL::ExecutionError, "Not authorized" unless play.owned_by?(current_actor)

        target = parse_actor_id(actor_id)
        raise GraphQL::ExecutionError, "Invalid participant" unless target
        raise GraphQL::ExecutionError, "Cannot remove the host" if play.owned_by?(target)

        remove_participant(play, target)
        block_actor(play, target) if block
        # Boot the client immediately, then nudge its progress sub (next save 403s).
        PresenceChannel.broadcast_to(play, { type: "kicked", actorId: actor_id })
        trigger_progress_updated(play)
        { success: true, errors: [] }
      end

      private

      def parse_actor_id(actor_id)
        kind, value = actor_id.to_s.split(":", 2)
        case kind
        when "user"
          user = User.find_by(id: value)
          user && Actor.new(user: user)
        when "guest"
          value.present? ? Actor.new(guest_token: value) : nil
        end
      end

      def remove_participant(play, target)
        scope = target.user? ? { user_id: target.user_id } : { guest_token: target.guest_token }
        play.participants.where(scope).destroy_all
      end

      def block_actor(play, target)
        attrs = target.user? ? { user_id: target.user_id } : { guest_token: target.guest_token }
        play.blocked_actors.find_or_create_by(attrs)
      end
    end
  end
end
