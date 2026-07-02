# Builds a user's merged, time-sorted public activity feed (published puzzles,
# reviews written, solves). Pulled out of UserType so the event-merging logic
# lives with the other domain services rather than in a GraphQL resolver.
#
# Visibility gates stay with the caller EXCEPT the solve-history one, which is
# structural: solves are only included when `include_solves` is true, so a feed
# can never leak solves the user has hidden.
class UserActivityFeed
  Event = Struct.new(:kind, :occurred_at, :puzzle, :comment, keyword_init: true)

  def self.build(user, limit:, include_solves:)
    new(user, limit:, include_solves:).build
  end

  def initialize(user, limit:, include_solves:)
    @user = user
    @limit = limit
    @include_solves = include_solves
  end

  def build
    events = published_events + review_events + (@include_solves ? solve_events : [])
    events.select(&:occurred_at).sort_by(&:occurred_at).reverse.first(@limit)
  end

  private

  def public_ids
    Puzzle.publicly_visible.select(:id)
  end

  def published_events
    @user.puzzles.publicly_visible.order(published_at: :desc).limit(@limit).map do |puzzle|
      Event.new(kind: "PUBLISHED_PUZZLE", occurred_at: puzzle.published_at, puzzle:, comment: nil)
    end
  end

  def review_events
    @user.comments.top_level.where(puzzle_id: public_ids).by_newest.limit(@limit)
         .includes(puzzle: :author).map do |comment|
      Event.new(kind: "REVIEW_WRITTEN", occurred_at: comment.created_at, puzzle: comment.puzzle, comment:)
    end
  end

  def solve_events
    @user.puzzle_plays.completed.where(puzzle_id: public_ids)
         .order(completed_at: :desc).limit(@limit).includes(puzzle: :author).map do |play|
      Event.new(kind: "SOLVE", occurred_at: play.completed_at || play.updated_at, puzzle: play.puzzle, comment: nil)
    end
  end
end
