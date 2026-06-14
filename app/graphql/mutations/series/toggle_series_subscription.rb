module Mutations
  module Series
    class ToggleSeriesSubscription < Mutations::BaseMutation
      description "Subscribe to or unsubscribe from a series"

      argument :series_id, ID, required: true, description: "ID of the series"

      field :subscribed, Boolean, null: false, description: "True if the user is now subscribed"
      field :subscriber_count, Integer, null: false, description: "Updated subscriber count"

      def resolve(series_id:)
        require_auth!
        series = ::Series.find_by(id: series_id)
        raise GraphQL::ExecutionError, "Series not found" unless series&.viewable_by?(current_user)

        subscription = current_user.series_subscriptions.find_by(series_id: series.id)
        if subscription
          subscription.destroy
          { subscribed: false, subscriber_count: series.series_subscriptions.count }
        else
          current_user.series_subscriptions.create!(series:)
          { subscribed: true, subscriber_count: series.series_subscriptions.count }
        end
      end
    end
  end
end
