# Shared by mutations and object types: is the current user mid-competition on
# a given puzzle? While true, the normal play surface must not leak correctness
# (solution hashes withheld, check/submit mutations rejected) — for ANY
# submission policy, since a solution hash lets a client self-check for free.
# Memoized per request in context so repeated fields cost one indexed EXISTS.
module CompetitionGuard
  def competing_on?(puzzle_id)
    user = context[:current_user]
    return false unless user

    cache = context[:competition_guard] ||= {}
    cache.fetch(puzzle_id) { cache[puzzle_id] = CompetitionRun.active_for?(user:, puzzle_id:) }
  end

  def reject_during_competition!(puzzle_id)
    return unless competing_on?(puzzle_id)

    raise GraphQL::ExecutionError,
      "This puzzle is part of a competition you're playing — submit it through the competition page"
  end
end
