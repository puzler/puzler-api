module Types
  module Objects
    # Aggregate public metrics about a user's contributions, resolved directly
    # from the User. Returned only when the viewer is allowed to see stats (the
    # owner, or any viewer when show_stats is on) — gated in UserType#profile_stats.
    # Computed from denormalized counters to stay cheap.
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

      def avg_rating_received
        object.puzzles.publicly_visible.where.not(avg_rating: nil).average(:avg_rating)&.to_f
      end

      def collection_count = object.collections.publicly_visible.count

      def reviews_received_count
        Comment.top_level.where(puzzle_id: object.puzzles.publicly_visible.select(:id)).count
      end

      def series_count = object.series.publicly_visible.count
      def total_favorites_received = object.puzzles.publicly_visible.sum(:favorite_count)
      def total_solves_received = object.puzzles.publicly_visible.sum(:solve_count)
    end
  end
end
