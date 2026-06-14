# Maps deployed git commits to sequential version numbers. The row id *is* the
# version number — the first time a commit is seen it gets the next id, and that
# number is stable forever after. Lookup is lazy (on first use, then memoized
# per process) rather than at boot, so it never interferes with db:prepare /
# rake tasks running before this table exists.
class AppVersion < ApplicationRecord
  validates :commit, presence: true, uniqueness: true

  class << self
    # Sequential version number for the running build (this commit's row id),
    # registering the commit if it's new. nil when the commit is unknown or the
    # table isn't available yet, so reporting a version never breaks a request.
    def number
      return @number if defined?(@number)

      @number = commit_sha.present? ? record_for(commit_sha)&.id : nil
    end

    # Eagerly register the running commit at startup (called from the Docker
    # entrypoint after db:prepare) so every deployed commit gets its own number,
    # even if no request ever reads it before the next deploy. Never raises — a
    # versioning hiccup must not abort a deploy.
    def register!
      record = number ? find_by(id: number) : nil
      Rails.logger.info("[AppVersion] running version #{number || "?"} (#{commit_sha || "unknown"})")
      record
    rescue StandardError => e
      Rails.logger.warn("[AppVersion] registration skipped: #{e.message}")
      nil
    end

    # Payload for the root endpoint.
    def info
      { version: number, commit: commit_sha, branch: branch }.compact
    end

    # Full git SHA of the running build. Render injects RENDER_GIT_COMMIT on
    # every deploy; in development we read .git/HEAD. Resolved once per process.
    def commit_sha
      return @commit_sha if defined?(@commit_sha)

      @commit_sha = ENV["RENDER_GIT_COMMIT"].presence || local_head
    end

    def branch
      ENV["RENDER_GIT_BRANCH"].presence
    end

    private

    # find_or_create with the unique index as the race guard: if a sibling
    # process inserts the same commit first, fall back to reading it.
    def record_for(sha)
      find_or_create_by!(commit: sha)
    rescue ActiveRecord::RecordNotUnique
      find_by(commit: sha)
    rescue ActiveRecord::ActiveRecordError
      nil # table missing / DB unavailable — degrade gracefully
    end

    # Read .git/HEAD directly (no shelling out); the .git dir is excluded from
    # the production image, so this only resolves off Render.
    def local_head
      head = Rails.root.join(".git", "HEAD")
      return nil unless head.exist?

      ref = head.read.strip
      return ref unless ref.start_with?("ref:")

      Rails.root.join(".git", ref.split(" ", 2).last).read.strip.presence
    rescue StandardError
      nil
    end
  end
end
