# Tracks which plays currently have at least one live PresenceChannel connection,
# so the pruner can tell an abandoned guest-hosted play (reap it) from one whose
# solvers are merely idle between saves (keep it).
#
# In-memory + Mutex-guarded, which is exact for the single-process dev/test setup
# (async cable adapter). NOTE: a multi-process production deploy (redis cable)
# would undercount across workers — PrunePlayJob's updated_at guard limits the
# blast radius (worst case a still-active room reaps slightly early and its link
# 404s until re-hosted). This module is the seam where a shared, redis-backed
# store would slot in for horizontal scale.
module PresenceRegistry
  @mutex = Mutex.new
  @plays = {} # play_id(String) => { connection_id => true }

  module_function

  def add(play_id, connection_id)
    @mutex.synchronize { (@plays[play_id.to_s] ||= {})[connection_id] = true }
  end

  def remove(play_id, connection_id)
    @mutex.synchronize do
      conns = @plays[play_id.to_s]
      next unless conns

      conns.delete(connection_id)
      @plays.delete(play_id.to_s) if conns.empty?
    end
  end

  def live?(play_id)
    @mutex.synchronize { @plays.fetch(play_id.to_s, nil)&.any? || false }
  end
end
