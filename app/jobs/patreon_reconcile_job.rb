class PatreonReconcileJob < ApplicationJob
  queue_as :default

  # Daily backstop for the webhook feed: refresh every live campaign (tiers,
  # webhook registration, token_stale recovery) and re-mirror its full member
  # list. RateLimited raises through so Sidekiq's retry backoff spaces out the
  # next attempt; per-campaign token failures are contained by the services.
  def perform
    PatreonCampaign.where(status: [ :active, :token_stale ]).find_each do |campaign|
      Patreon::SyncCreatorCampaign.call(campaign.user)

      campaign.reload
      next unless campaign.status_active?

      begin
        Patreon::ReconcileCampaignMembers.call(campaign)
      rescue Patreon::Token::RefreshFailed
        campaign.update!(status: :token_stale)
      end
    end
  end
end
