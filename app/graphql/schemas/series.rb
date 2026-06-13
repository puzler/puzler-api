module Schemas
  module Series
    module Queries
      include Types::Interfaces::BaseInterface
      description "Series queries"
      graphql_name "SeriesQueries"

      field :series, Types::Objects::SeriesType, null: true,
        description: "Find a series by ID, if the current user is allowed to see it" do
        argument :id, ID, required: true, description: "Series ID to look up"
      end

      field :series_by_token, Types::Objects::SeriesType, null: true,
        description: "Find a series by its share token (for unlisted links)" do
        argument :token, String, required: true, description: "The series' share token"
      end

      field :my_series, [ Types::Objects::SeriesType ], null: false,
        description: "The current user's series, newest first"

      field :my_subscriptions, [ Types::Objects::SeriesType ], null: false,
        description: "Series the current user is subscribed to, newest subscription first"

      def series(id:)
        record = ::Series.find_by(id:)
        return nil unless record&.viewable_by?(context[:current_user])

        record
      end

      def series_by_token(token:)
        record = ::Series.find_by(share_token: token)
        return nil unless record&.viewable_by?(context[:current_user], share_token: token)

        record
      end

      def my_series
        require_current_user!
        context[:current_user].series.order(created_at: :desc)
      end

      def my_subscriptions
        require_current_user!
        context[:current_user].series_subscriptions
                              .order(created_at: :desc)
                              .map(&:series)
      end

      private

      def require_current_user!
        raise GraphQL::ExecutionError, "Authentication required" unless context[:current_user]
      end
    end

    module Mutations
      include Types::Interfaces::BaseInterface
      description "Mutations for managing series"
      graphql_name "SeriesMutations"

      field :add_series_entry, mutation: ::Mutations::Series::AddSeriesEntry,
        description: "Add a puzzle or collection to a series"
      field :create_series, mutation: ::Mutations::Series::CreateSeries,
        description: "Create a series"
      field :delete_series, mutation: ::Mutations::Series::DeleteSeries,
        description: "Delete a series"
      field :remove_series_entry, mutation: ::Mutations::Series::RemoveSeriesEntry,
        description: "Remove an entry from a series"
      field :reorder_series_entries, mutation: ::Mutations::Series::ReorderSeriesEntries,
        description: "Reorder the entries in a series"
      field :toggle_series_subscription, mutation: ::Mutations::Series::ToggleSeriesSubscription,
        description: "Subscribe to or unsubscribe from a series"
      field :update_series, mutation: ::Mutations::Series::UpdateSeries,
        description: "Update a series' metadata"
    end
  end
end
