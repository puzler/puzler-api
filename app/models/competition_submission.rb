# A solver's submission state for one puzzle within a competition run. One row
# per run+puzzle: resubmissions overwrite it, so `correct` always reflects the
# LAST submission (what gets scored). The verdict is graded on write but only
# revealed according to the collection's submission policy.
class CompetitionSubmission < ApplicationRecord
  belongs_to :competition_run
  belongs_to :puzzle

  validates :puzzle_id, uniqueness: { scope: :competition_run_id }
end
