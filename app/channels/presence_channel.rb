# Real-time presence + multiplayer cursors for a play session, riding the same
# authenticated cable connection as everything else. Every outgoing message is
# server-stamped with the sender's actorId (user/guest key) and isHost flag so
# neither can be spoofed; the displayName is client-supplied and purely cosmetic.
class PresenceChannel < ApplicationCable::Channel
  def subscribed
    @play = PuzzlePlay.find_by(id: params[:play_id])
    return reject unless @play&.accessible_by?(current_actor)

    stream_for @play
    PresenceRegistry.add(@play.id, connection_id)
    broadcast_join(params[:display_name])
  end

  def unsubscribed
    return unless @play

    PresenceRegistry.remove(@play.id, connection_id)
    PresenceChannel.broadcast_to(@play, stamp({ type: "leave" }, nil))
    # Reap the room shortly after it empties, if it was a transient guest-host.
    PrunePlayJob.set(wait: PrunePlayJob::GRACE).perform_later(@play.id) if @play.guest_hosted?
  end

  # A newcomer asks the existing clients to re-announce themselves so it learns the
  # full roster. Also the re-broadcast a client sends after renaming itself.
  def announce(data)
    broadcast_join(data["display_name"])
  end

  def cursor(data)
    cells = Array(data["cells"]).first(81)
    PresenceChannel.broadcast_to(@play, stamp({ type: "cursor", cells: cells }, data["display_name"]))
  end

  private

  def broadcast_join(display_name)
    PresenceChannel.broadcast_to(@play, stamp({ type: "join" }, display_name))
  end

  def stamp(payload, display_name)
    payload.merge(
      actorId: current_actor.key,
      isHost: @play.owned_by?(current_actor),
      displayName: display_name
    )
  end

  # Per-subscription id (this channel instance) so two tabs of the same actor count
  # as two live connections — closing one leaves the room live for the other.
  def connection_id
    object_id
  end
end
