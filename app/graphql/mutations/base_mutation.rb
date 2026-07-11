# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    include CompetitionGuard

    argument_class Types::Arguments::BaseArgument
    field_class Types::Fields::BaseField
    input_object_class Types::InputObjects::BaseInputObject
    object_class Types::Objects::BaseObject

    private

    def current_user
      context[:current_user]
    end

    def guest_token
      context[:guest_token]
    end

    def request_ip
      context[:request_ip]
    end

    # The acting identity: a logged-in user OR a guest (see app/models/actor.rb).
    def current_actor
      Actor.from_context(current_user: current_user, guest_token: guest_token)
    end

    def require_auth!
      raise GraphQL::ExecutionError, "Authentication required" unless current_user
    end

    def require_actor!
      raise GraphQL::ExecutionError, "Identity required" unless current_actor
    end

    # Fetch a record the caller must own, via a current_user association
    # (passed by name so nothing touches current_user before the auth check).
    # Raises the conventional "<Label> not found" error otherwise —
    # deliberately indistinguishable from a nonexistent id, so ownership
    # can't be probed by id-guessing.
    def require_owned!(association, label, **finder)
      require_auth!
      current_user.public_send(association).find_by(**finder) ||
        raise(GraphQL::ExecutionError, "#{label} not found")
    end

    # Broadcast a play session's latest state to everyone watching it (the owner's
    # other tabs/devices; collaborators in Phase 7).
    def trigger_progress_updated(play)
      ApiSchema.subscriptions.trigger(:progress_updated, { puzzle_play_id: play.id }, play)
    end
  end
end
