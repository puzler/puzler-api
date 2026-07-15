require "rails_helper"

RSpec.describe Patreon::SyncCreatorCampaign do
  let(:creator) { create(:user) }
  let!(:identity) do
    create(:user_oauth_identity, :patreon, user: creator, expires_at: 20.days.from_now,
      scopes: "identity identity.memberships campaigns campaigns.members w:campaigns.webhook")
  end

  it "does nothing without the campaigns scope", :aggregate_failures do
    identity.update!(scopes: "identity identity.memberships")
    expect(described_class.call(creator)).to be_nil
    expect(a_request(:get, %r{/campaigns})).not_to have_been_made
  end

  it "returns nil for non-creators and marks a previously mirrored campaign removed", :aggregate_failures do
    existing = create(:patreon_campaign, user: creator)
    stub_patreon_campaigns([])

    expect(described_class.call(creator)).to be_nil
    expect(existing.reload).to be_status_removed
  end

  context "with a campaign" do
    before do
      stub_patreon_campaigns([ { id: "camp-9", title: "Puzzles Weekly", currency: "EUR" } ])
      stub_patreon_campaign_tiers("camp-9", [
        { id: "t-low", title: "Bronze", amount_cents: 300 },
        { id: "t-high", title: "Gold", amount_cents: 1000 }
      ])
      stub_patreon_webhook_create(webhook_id: "wh-1", secret: "hook-secret")
    end

    it "mirrors the campaign metadata", :aggregate_failures do
      campaign = described_class.call(creator)
      expect(campaign).to be_status_active
      expect(campaign).to have_attributes(patreon_id: "camp-9", title: "Puzzles Weekly", currency: "EUR")
      expect(campaign.campaign_synced_at).to be_present
    end

    it "mirrors the tiers" do
      campaign = described_class.call(creator)
      expect(campaign.tiers.pluck(:patreon_id, :amount_cents))
        .to contain_exactly([ "t-low", 300 ], [ "t-high", 1000 ])
    end

    it "registers the members webhook and stores its secret" do
      campaign = described_class.call(creator)
      expect(campaign).to have_attributes(webhook_patreon_id: "wh-1", webhook_secret: "hook-secret")
    end

    # A pre-existing mirrored campaign row for camp-9 (webhook registered).
    def mirrored_campaign(**attrs)
      create(:patreon_campaign, { user: creator, patreon_id: "camp-9",
        webhook_patreon_id: "wh-1", webhook_secret: "s" }.merge(attrs))
    end

    # [a tier that vanished from Patreon, a discarded tier that returned]
    def tier_sweep_fixtures
      campaign = mirrored_campaign
      [ create(:patreon_tier, patreon_campaign: campaign, patreon_id: "t-gone"),
        create(:patreon_tier, :discarded, patreon_campaign: campaign, patreon_id: "t-low") ]
    end

    it "discards tiers that vanished and resurrects ones that return", :aggregate_failures do
      gone, returned = tier_sweep_fixtures
      described_class.call(creator)
      expect(gone.reload).to be_discarded
      expect(returned.reload).not_to be_discarded
    end

    it "recovers a token_stale campaign on a successful sync" do
      campaign = mirrored_campaign(status: :token_stale)
      described_class.call(creator)
      expect(campaign.reload).to be_status_active
    end

    it "unpauses a paused webhook instead of re-creating it", :aggregate_failures do
      mirrored_campaign(webhook_paused_at: 1.day.ago)
      stub_patreon_webhook_update("wh-1")

      expect(described_class.call(creator).webhook_paused_at).to be_nil
      expect(a_request(:patch, %r{/webhooks/wh-1})).to have_been_made
      expect(a_request(:post, %r{/webhooks$})).not_to have_been_made
    end
  end

  it "marks the campaign token_stale when the refresh token is rejected", :aggregate_failures do
    campaign = create(:patreon_campaign, user: creator)
    identity.update!(expires_at: nil) # forces a proactive refresh
    stub_patreon_token_refresh(status: 400)

    expect(described_class.call(creator)).to be_nil
    expect(campaign.reload).to be_status_token_stale
  end
end
