# frozen_string_literal: true

module Types
  module Objects
    class SubscriptionType < BaseObject
      description "Realtime events delivered over ActionCable"

      field :progress_updated, subscription: ::Subscriptions::ProgressUpdated,
        description: "A watched play session's progress changed (live sync / collaboration)"
    end
  end
end
