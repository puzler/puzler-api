require "rails_helper"

RSpec.describe Patreon::SyncPatronMemberships do
  let(:patron) { create(:user) }
  let!(:identity) do
    create(:user_oauth_identity, :patreon, user: patron,
      expires_at: 20.days.from_now, scopes: "identity identity.memberships")
  end
  let(:campaign) { create(:patreon_campaign) }

  it "does nothing without the memberships scope (pre-feature identities)", :aggregate_failures do
    identity.update!(scopes: "identity")
    expect(described_class.call(patron)).to be(false)
    expect(a_request(:get, %r{/identity})).not_to have_been_made
  end

  describe "mirroring" do
    before do
      stub_patreon_identity_memberships([
        { campaign_id: campaign.patreon_id, status: "active_patron", amount_cents: 500,
          tier_ids: [ "t1" ], pledge_start: 2.months.ago, member_id: "m-1" },
        { campaign_id: "not-on-puzler", status: "active_patron", amount_cents: 300 }
      ])
      described_class.call(patron)
    end

    it "keeps only memberships for Puzler campaigns" do
      expect(patron.patreon_memberships.pluck(:patreon_campaign_id)).to eq([ campaign.id ])
    end

    it "mirrors status, entitlement, and identity fields", :aggregate_failures do
      m = patron.patreon_memberships.first
      expect(m).to be_patron_active_patron
      expect(m).to have_attributes(entitled_amount_cents: 500, entitled_patreon_tier_ids: [ "t1" ],
        patreon_member_id: "m-1")
    end

    it "records both join dates for the back-catalog gate", :aggregate_failures do
      m = patron.patreon_memberships.first
      expect(m.pledge_relationship_start).to be_within(1.minute).of(2.months.ago)
      expect(m.first_active_at).to be_present
    end
  end

  def sync_with(membership_attrs)
    stub_patreon_identity_memberships([ { campaign_id: campaign.patreon_id, **membership_attrs } ])
    described_class.call(patron)
    patron.patreon_memberships.first
  end

  it "handles the custom-pledge caveat (active patron, empty entitled tiers)", :aggregate_failures do
    m = sync_with(status: "active_patron", amount_cents: 450, tier_ids: [])
    expect(m).to be_patron_active_patron
    expect(m).to have_attributes(entitled_patreon_tier_ids: [], entitled_amount_cents: 450)
  end

  it "maps a null patron_status (follower) to unknown" do
    stub_patreon_identity_memberships([
      { campaign_id: campaign.patreon_id, status: nil, amount_cents: 0 }
    ])

    described_class.call(patron)
    expect(patron.patreon_memberships.first).to be_patron_unknown
  end

  def long_time_member(**attrs)
    create(:patreon_membership, { user: patron, patreon_campaign: campaign,
      first_active_at: 1.year.ago }.merge(attrs))
  end

  it "demotes memberships absent from the response but keeps their join dates", :aggregate_failures do
    stale = long_time_member(pledge_relationship_start: 1.year.ago)
    stub_patreon_identity_memberships([])
    described_class.call(patron)
    expect(stale.reload).to be_patron_former_patron.and have_attributes(entitled_amount_cents: 0)
    expect(stale.first_active_at).to be_within(1.minute).of(1.year.ago)
  end

  it "never overwrites first_active_at on later syncs" do
    existing = long_time_member
    sync_with(status: "active_patron", amount_cents: 300)
    expect(existing.reload.first_active_at).to be_within(1.minute).of(1.year.ago)
  end
end
