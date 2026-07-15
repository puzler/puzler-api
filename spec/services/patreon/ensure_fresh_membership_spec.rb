require "rails_helper"

RSpec.describe Patreon::EnsureFreshMembership do
  let(:patron) { create(:user) }
  let(:campaign) { create(:patreon_campaign) }
  let!(:identity) do
    create(:user_oauth_identity, :patreon, user: patron,
      expires_at: 20.days.from_now, scopes: "identity identity.memberships")
  end

  around do |example|
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original
  end

  def stub_active_membership
    stub_patreon_identity_memberships([
      { campaign_id: campaign.patreon_id, status: "active_patron", amount_cents: 300 }
    ])
  end

  it "skips the sync entirely when the cached row is fresh", :aggregate_failures do
    create(:patreon_membership, user: patron, patreon_campaign: campaign, synced_at: 1.minute.ago)
    expect(described_class.call(patron, campaign)).to be(false)
    expect(a_request(:get, %r{/identity})).not_to have_been_made
  end

  it "syncs when the row is stale", :aggregate_failures do
    create(:patreon_membership, user: patron, patreon_campaign: campaign, synced_at: 1.hour.ago)
    stub_active_membership
    expect(described_class.call(patron, campaign)).to be(true)
    expect(patron.patreon_memberships.first.synced_at).to be_within(5.seconds).of(Time.current)
  end

  it "syncs when no row exists (brand-new pledge unlocks within one page load)" do
    stub_active_membership
    expect(described_class.call(patron, campaign)).to be(true)
  end

  it "throttles to one sync per user per window", :aggregate_failures do
    stub_patreon_identity_memberships([])
    expect(described_class.call(patron, campaign)).to be(true)
    expect(described_class.call(patron, campaign)).to be(false)
    expect(a_request(:get, %r{/identity})).to have_been_made.once
  end

  it "swallows Patreon failures (cached answer stands)" do
    identity.update!(expires_at: nil)
    stub_patreon_token_refresh(status: 400)
    expect(described_class.call(patron, campaign)).to be(false)
  end

  it "is a no-op for guests" do
    expect(described_class.call(nil, campaign)).to be(false)
  end
end
