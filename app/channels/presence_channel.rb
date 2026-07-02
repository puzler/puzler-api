# Real-time presence + multiplayer cursors for a play session, riding the same
# authenticated cable connection as everything else. Every outgoing message is
# server-stamped with the sender's actorId (user/guest key) and isHost flag so
# neither can be spoofed; the displayName is client-supplied and purely cosmetic.
class PresenceChannel < ApplicationCable::Channel
  # Generous cap on cells per relay message: covers a full board on the largest
  # supported grids while bounding what one message can carry.
  MAX_RELAY_CELLS = 512

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
    PresenceRegistry.add(@play.id, connection_id) # refresh liveness TTL (heartbeat)
    broadcast_join(data["display_name"])
  end

  def cursor(data)
    return unless relayable?

    cells = Array(data["cells"]).first(81)
    PresenceChannel.broadcast_to(@play, stamp({ type: "cursor", cells: cells }, data["display_name"]))
  end

  # Live cell-state relay: fan a batch of changed cells out to the other clients
  # on this play, so collaborators see edits immediately instead of waiting for
  # the debounced SaveProgress autosave. Purely ephemeral — nothing is persisted
  # here; SaveProgress remains the durable path and late joiners hydrate from it.
  def cells(data)
    return unless relayable?

    states = data["states"]
    return unless states.is_a?(Hash) && states.size <= MAX_RELAY_CELLS

    PresenceChannel.broadcast_to(@play, stamp({ type: "cells", states: states }, nil))
  end

  # A (re)connecting client asks peers to re-relay their full boards, so it
  # catches up on edits it missed while its cable was down (relays are
  # fire-and-forget and never replayed).
  def request_cells(_data = {})
    return unless relayable?

    PresenceChannel.broadcast_to(@play, stamp({ type: "request_cells" }, nil))
  end

  private

  # Kicking removes the participant row (and optionally blocks the actor), but a
  # kicked client's existing subscription lives on until it unsubscribes. Re-check
  # access on every relay action so that lingering subscription can't keep
  # injecting cursor or cell state into the session.
  def relayable?
    @play.accessible_by?(current_actor)
  end

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

  # A process-unique id for this subscription so two tabs of the same actor count
  # as two live connections (closing one leaves the room live for the other), and
  # so ids never collide across web processes the way object_id could.
  def connection_id
    @connection_id ||= SecureRandom.uuid
  end
end
