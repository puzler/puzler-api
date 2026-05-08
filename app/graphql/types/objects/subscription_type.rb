module Types
  module Objects
    class SubscriptionType < BaseObject
      description "WebSocket subscriptions — scaffolded for future collaborative and live features"

      # WebSocket foundation — no features yet, but the channel is wired up.
      # Future use: collaborative solving events, live competition stats.
      field :puzzle_session_event, String, null: true,
        description: "Real-time events for a puzzle session" do
        argument :puzzle_id, ID, required: true, description: "ID of the puzzle session to subscribe to"
      end

      def puzzle_session_event(puzzle_id:)
        object
      end
    end
  end
end
