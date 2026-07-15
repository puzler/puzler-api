module Patreon
  # On-demand freshness for a single viewer at a lock decision: when a patron
  # is about to be told "locked" but their cached membership is missing or
  # stale, sync synchronously so a brand-new pledge unlocks within one page
  # load. Cache-throttled per user so a hammering client can't burn Patreon
  # rate limit; never called from list scopes. Best-effort by design — any
  # Patreon failure just leaves the cached answer standing.
  class EnsureFreshMembership
    MAX_AGE = 15.minutes
    THROTTLE_TTL = 10.minutes

    def self.call(user, campaign)
      return false unless user && campaign

      membership = PatreonMembership.find_by(user:, patreon_campaign: campaign)
      return false if membership && membership.synced_at > MAX_AGE.ago

      # unless_exist makes the cache write the throttle: only one sync per user
      # per TTL window, no matter how many gated pages they hit.
      return false unless Rails.cache.write("patreon_membership_sync:#{user.id}", true,
        unless_exist: true, expires_in: THROTTLE_TTL)

      SyncPatronMemberships.call(user, source: :on_demand)
    rescue Token::RefreshFailed, Client::Error
      false
    end
  end
end
