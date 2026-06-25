# frozen_string_literal: true

module Subscriptions
  # Pushes a play session's latest state to everyone watching it: the owner's
  # other tabs/devices (Phase 6) and, later, accepted collaborators (Phase 7).
  # The cable connection is authenticated, so we authorize by current_user via
  # PuzzlePlay#accessible_by? rather than a capability token.
  class ProgressUpdated < Subscriptions::BaseSubscription
    description "Fires when a watched play session's progress changes"

    argument :puzzle_play_id, ID, required: true,
      description: "The play session to watch"

    field :puzzle_play, Types::Objects::PuzzlePlayType, null: false,
      description: "The updated play session"

    def subscribe(puzzle_play_id:)
      play = PuzzlePlay.find_by(id: puzzle_play_id)
      raise GraphQL::ExecutionError, "Play session not found" unless play
      raise GraphQL::ExecutionError, "Not authorized" unless play.accessible_by?(context[:current_user])

      :no_response
    end

    def update(puzzle_play_id:)
      { puzzle_play: object }
    end
  end
end
