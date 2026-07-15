class PatreonMembershipSyncJob < ApplicationJob
  queue_as :default

  # Patron-side membership sync, run async off the OAuth callback. A refresh
  # failure means the user must re-run OAuth — nothing a retry can fix, and the
  # settings page surfaces the reconnect prompt.
  def perform(user_id)
    user = User.find_by(id: user_id)
    Patreon::SyncPatronMemberships.call(user) if user
  rescue Patreon::Token::RefreshFailed
    nil
  end
end
