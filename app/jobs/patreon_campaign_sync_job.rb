class PatreonCampaignSyncJob < ApplicationJob
  queue_as :default

  # Creator-side campaign/tier/webhook sync, run async off the OAuth callback.
  def perform(user_id)
    user = User.find_by(id: user_id)
    Patreon::SyncCreatorCampaign.call(user) if user
  end
end
