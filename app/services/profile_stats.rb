# Aggregate public metrics for a user's profile, computed in one pass and
# cached briefly. Six COUNT/SUM/AVG queries per profile view is fine today,
# but the numbers change slowly and profiles are the most re-visited public
# pages, so a short TTL removes the recomputation for free. Slight staleness
# (up to TTL) is acceptable for display-only stats.
class ProfileStats
  TTL = 5.minutes

  Stats = Struct.new(
    :avg_rating_received, :collection_count, :reviews_received_count,
    :series_count, :total_favorites_received, :total_solves_received,
    keyword_init: true
  )

  def self.for(user)
    values = Rails.cache.fetch("profile_stats/v1/#{user.id}", expires_in: TTL) { compute(user) }
    Stats.new(**values)
  end

  def self.compute(user)
    public_puzzles = user.puzzles.publicly_visible
    {
      avg_rating_received: public_puzzles.where.not(avg_rating: nil).average(:avg_rating)&.to_f,
      collection_count: user.collections.publicly_visible.count,
      reviews_received_count: Comment.top_level.where(puzzle_id: public_puzzles.select(:id)).count,
      series_count: user.series.publicly_visible.count,
      total_favorites_received: public_puzzles.sum(:favorite_count),
      total_solves_received: public_puzzles.sum(:solve_count)
    }
  end
end
