# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
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

    # Broadcast a play session's latest state to everyone watching it (the owner's
    # other tabs/devices; collaborators in Phase 7).
    def trigger_progress_updated(play)
      ApiSchema.subscriptions.trigger(:progress_updated, { puzzle_play_id: play.id }, play)
    end
  end
end
