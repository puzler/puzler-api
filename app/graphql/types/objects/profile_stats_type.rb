module Types
  module Objects
    # Aggregate public metrics about a user's contributions, resolved from the
    # User via the briefly-cached ProfileStats service. Returned only when the
    # viewer is allowed to see stats (the owner, or any viewer when show_stats
    # is on) — gated in UserType#profile_stats.
    class ProfileStatsType < BaseObject
      description "Aggregate public metrics about a user's contributions"

      field :avg_rating_received, Float, null: true,
        description: "Average star rating across this user's rated public puzzles"
      field :collection_count, Integer, null: false, description: "Number of public collections"
      field :joined_at, GraphQL::Types::ISO8601DateTime, null: false, method: :created_at,
        description: "When the account was created"
      field :reviews_received_count, Integer, null: false,
        description: "Number of reviews left on this user's public puzzles"
      field :series_count, Integer, null: false, description: "Number of public series"
      field :total_favorites_received, Integer, null: false,
        description: "Total favorites across this user's public puzzles"
      field :total_solves_received, Integer, null: false,
        description: "Total solves across this user's public puzzles"

      def avg_rating_received = stats.avg_rating_received
      def collection_count = stats.collection_count
      def reviews_received_count = stats.reviews_received_count
      def series_count = stats.series_count
      def total_favorites_received = stats.total_favorites_received
      def total_solves_received = stats.total_solves_received

      private

      # One computation (or cache hit) per rendered stats block.
      def stats = @stats ||= ProfileStats.for(object)
    end
  end
end
