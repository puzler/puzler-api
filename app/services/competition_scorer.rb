# Turns a finished competition run into its score breakdown. Pure computation
# over the run's submissions and the collection's config; CompetitionRun#finalize!
# persists the result.
#
# base    — sum of entry points for puzzles whose final submission is correct.
# penalty — blind policy: penalty × incorrect FINAL submissions (resubmitting
#           is free; only a wrong answer left standing costs). instant/single:
#           penalty × every wrong submission made.
# bonus   — only when every puzzle in the collection is correct: the author's
#           bonus-per-minute × whole minutes left on the clock (floored).
# total   — base − penalty + bonus, clamped at zero unless the author allows
#           negative scores.
class CompetitionScorer
  def initialize(run)
    @run = run
    @collection = run.collection
  end

  def breakdown
    base = correct_entries.sum(&:points)
    penalty = penalty_total
    bonus = bonus_total
    total = base - penalty + bonus
    total = [ total, 0 ].max if @collection.clamp_score_at_zero?

    {
      base_points: base,
      penalty_points: penalty,
      bonus_points: bonus,
      total_points: total,
      correct_count: correct_ids.size,
      time_used_seconds: (@run.effective_end - @run.started_at).to_i
    }
  end

  private

  def puzzle_entries
    @puzzle_entries ||= @collection.puzzle_entries.to_a
  end

  def submissions
    @submissions ||= @run.submissions.to_a
  end

  def correct_ids
    @correct_ids ||= submissions.select(&:correct).map(&:puzzle_id).to_set
  end

  def correct_entries
    puzzle_entries.select { |e| correct_ids.include?(e.entryable_id) }
  end

  def penalty_total
    per = @collection.penalty_points
    return 0 if per.zero?

    if @collection.policy_blind?
      per * submissions.count { |s| !s.correct }
    else
      per * submissions.sum(&:wrong_attempts)
    end
  end

  def bonus_total
    return 0 if puzzle_entries.empty?
    return 0 unless puzzle_entries.all? { |e| correct_ids.include?(e.entryable_id) }

    remaining = (@run.deadline - @run.effective_end).to_i
    @collection.bonus_points_per_minute * (remaining / 60)
  end
end
