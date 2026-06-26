# Tracks which plays currently have at least one live PresenceChannel connection,
# so PrunePlayJob can tell an abandoned guest-hosted play (reap it) from one whose
# solvers are merely idle between saves (keep it).
#
# Two backends behind one interface:
#   MemoryStore (dev/test) — a Mutex-guarded Hash, exact for the single-process
#     async setup.
#   RedisStore (production) — a Redis SET per play, shared across every web
#     instance AND the Sidekiq worker that runs the prune (the in-memory store
#     can't span processes). A short TTL, refreshed on connect and on the client's
#     presence heartbeat, self-heals entries orphaned by a crashed process; clean
#     disconnects SREM immediately.
module PresenceRegistry
  TTL_SECONDS = 90

  class MemoryStore
    def initialize
      @mutex = Mutex.new
      @plays = {} # play_id => { connection_id => true }
    end

    def add(play_id, connection_id)
      @mutex.synchronize { (@plays[play_id] ||= {})[connection_id] = true }
    end

    def remove(play_id, connection_id)
      @mutex.synchronize do
        conns = @plays[play_id]
        next unless conns

        conns.delete(connection_id)
        @plays.delete(play_id) if conns.empty?
      end
    end

    def live?(play_id)
      @mutex.synchronize { @plays.fetch(play_id, nil)&.any? || false }
    end

    def reset!
      @mutex.synchronize { @plays.clear }
    end
  end

  class RedisStore
    def add(play_id, connection_id)
      Sidekiq.redis do |r|
        r.call("SADD", key(play_id), connection_id)
        r.call("EXPIRE", key(play_id), TTL_SECONDS)
      end
    end

    def remove(play_id, connection_id)
      Sidekiq.redis { |r| r.call("SREM", key(play_id), connection_id) }
    end

    def live?(play_id)
      Sidekiq.redis { |r| r.call("SCARD", key(play_id)).to_i.positive? }
    end

    private

    def key(play_id)
      "presence:play:#{play_id}"
    end
  end

  module_function

  def add(play_id, connection_id)
    backend.add(play_id.to_s, connection_id.to_s)
  end

  def remove(play_id, connection_id)
    backend.remove(play_id.to_s, connection_id.to_s)
  end

  def live?(play_id)
    backend.live?(play_id.to_s)
  end

  # Test hygiene: clear the in-memory store between examples.
  def reset!
    backend.reset! if backend.respond_to?(:reset!)
  end

  def backend
    @backend ||= Rails.env.production? ? RedisStore.new : MemoryStore.new
  end
end
