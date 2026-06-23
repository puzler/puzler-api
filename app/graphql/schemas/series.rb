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

      field :my_series, Types::Objects::SeriesConnectionType, null: false, connection: false,
        description: "A page of the current user's series, with search/filter/sort" do
        argument :filter, Types::InputObjects::ListingFilterInput, required: false,
          description: "Search, filter, sort, and pagination options"
      end

      field :public_series, Types::Objects::SeriesConnectionType, null: false, connection: false,
        description: "Browse the public series archive with search/filter/sort/pagination" do
        argument :filter, Types::InputObjects::ListingFilterInput, required: false,
          description: "Search, filter, sort, and pagination options"
      end

      field :my_subscriptions, [ Types::Objects::SeriesType ], null: false,
        description: "Series the current user is subscribed to, newest subscription first"

      field :series_feed, [ Types::Objects::SeriesEntryType ], null: false,
        description: "Recently-released entries across the current user's subscribed series, newest first"

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

      def my_series(filter: nil)
        require_current_user!
        scope = context[:current_user].series.includes(:author)
        args = filter ? filter.to_listing_args : {}
        OwnedListing.apply(scope, **args)
      end

      def public_series(filter: nil)
        scope = ::Series.publicly_visible.includes(:author)
        args = filter ? filter.to_listing_args : {}
        OwnedListing.apply(scope, **args)
      end

      def my_subscriptions
        require_current_user!
        context[:current_user].series_subscriptions
                              .order(created_at: :desc)
                              .map(&:series)
      end

      # "New in your series": released entries from subscribed series the user
      # can still see and whose target is public, newest release first.
      def series_feed
        require_current_user!
        user = context[:current_user]
        series_ids = user.series_subscriptions.pluck(:series_id)
        return [] if series_ids.empty?

        viewable = ::Series.where(id: series_ids).select { |s| s.viewable_by?(user) }.index_by(&:id)
        entries = SeriesEntry.released.where(series_id: viewable.keys).includes(:entryable, :series)
        entries.select(&:viewable_in_container?)
               .sort_by(&:effective_release_at).reverse.first(50)
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
      field :schedule_series_entry, mutation: ::Mutations::Series::ScheduleSeriesEntry,
        description: "Set or clear a series entry's scheduled release time"
      field :toggle_series_subscription, mutation: ::Mutations::Series::ToggleSeriesSubscription,
        description: "Subscribe to or unsubscribe from a series"
      field :update_series, mutation: ::Mutations::Series::UpdateSeries,
        description: "Update a series' metadata"
    end
  end
end
