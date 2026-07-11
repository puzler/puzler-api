# One solver's single timed attempt at a competition collection. The server is
# the clock: the deadline was frozen at start, submissions are accepted only
# while active (with a small grace for network latency), and scoring happens at
# finalization — lazily, whenever an ended run is next read, so no scheduled
# job is required and dev behaves like production.
class CompetitionRun < ApplicationRecord
  # Submissions arriving up to this many seconds past the deadline are accepted
  # (latency courtesy); the grace never extends scored time or the bonus.
  GRACE_SECONDS = 5

  belongs_to :collection
  belongs_to :user

  has_many :submissions, class_name: "CompetitionSubmission", dependent: :destroy

  def active?
    finished_at.nil? && Time.current <= deadline + GRACE_SECONDS
  end

  def ended?
    !active?
  end

  def final?
    finalized_at.present?
  end

  # The moment the run stopped counting: an early finish, else the deadline.
  # Clamped so grace-window submissions never extend scored time.
  def effective_end
    [ finished_at || deadline, deadline ].min
  end

  def seconds_remaining
    [ (deadline - Time.current).to_i, 0 ].max
  end

  # Compute and freeze the score. Idempotent; safe to call from any read path.
  def finalize!
    return self if final?

    with_lock do
      break if final?

      assign_attributes(CompetitionScorer.new(self).breakdown.merge(finalized_at: Time.current))
      save!
    end
    self
  end

  def ensure_finalized!
    finalize! if !final? && ended?
    self
  end

  # Does `user` currently have a live run containing this puzzle? The leak
  # guard for normal play paths (solution hashes, check/submit mutations).
  def self.active_for?(user:, puzzle_id:)
    return false unless user

    where(user:, finished_at: nil)
      .where("deadline >= ?", Time.current - GRACE_SECONDS)
      .joins(collection: :puzzle_entries)
      .where(collection_entries: { entryable_id: puzzle_id })
      .exists?
  end
end
