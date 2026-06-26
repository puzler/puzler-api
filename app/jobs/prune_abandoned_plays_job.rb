class PruneAbandonedPlaysJob < ApplicationJob
  queue_as :default

  # Backstop sweep for guest-hosted rooms the presence-driven PrunePlayJob never
  # reaped — e.g. the server died before `unsubscribed` could enqueue one, so no
  # disconnect ever fired. Conservative: only rooms idle well over an hour AND with
  # no live connection. A connected-but-idle solver keeps a registry entry alive via
  # the 25s presence heartbeat, so live? spares them; a crashed room's entries have
  # long since expired. Runs hourly on the Sidekiq worker (see the sidekiq initializer).
  IDLE_THRESHOLD = 1.hour

  def perform
    PuzzlePlay.guest_hosted.in_progress
      .where(updated_at: ..IDLE_THRESHOLD.ago)
      .find_each { |play| play.destroy unless PresenceRegistry.live?(play.id) }
  end
end
