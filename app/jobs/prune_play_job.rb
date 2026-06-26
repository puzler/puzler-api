class PrunePlayJob < ApplicationJob
  queue_as :default

  # Grace window between a disconnect and the reap attempt, also reused as the
  # "has it gone quiet?" threshold below.
  GRACE = 30.seconds

  # Reap a guest-hosted play once its room empties. Enqueued (delayed by GRACE) on
  # every PresenceChannel disconnect. Guarded three ways so we never delete a live
  # session: it must still be guest-hosted + unsolved, have no live connection, and
  # have gone quiet (no save bumped updated_at within the window — covers a solver
  # who is connected but idle). User-owned plays are persistent and never pruned.
  def perform(play_id)
    play = PuzzlePlay.guest_hosted.in_progress.find_by(id: play_id)
    return unless play
    return if PresenceRegistry.live?(play.id)
    return if play.updated_at > GRACE.ago

    play.destroy
  end
end
