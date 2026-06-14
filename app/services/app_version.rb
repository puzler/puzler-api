# Resolves the running build's git commit so the root endpoint can report which
# version is deployed — no manual bumping. On Render, RENDER_GIT_COMMIT (and
# RENDER_GIT_BRANCH) are injected automatically on every deploy; in development
# we fall back to reading the repo's HEAD. Resolved once per process since none
# of these change while the app is running.
module AppVersion
  module_function

  def commit
    return @commit if defined?(@commit)

    @commit = ENV["RENDER_GIT_COMMIT"].presence || local_head || "unknown"
  end

  def short
    commit == "unknown" ? "unknown" : commit[0, 9]
  end

  def branch
    ENV["RENDER_GIT_BRANCH"].presence
  end

  # { commit:, version:, branch: } for the root payload (branch dropped if blank).
  def info
    { version: short, commit:, branch: }.compact
  end

  # Read .git/HEAD directly (no shelling out) for local dev; the .git directory
  # is excluded from the production image, so this only runs off Render.
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
