require "rails_helper"

RSpec.describe Patreon::ReconcileCampaignMembers do
  let(:creator) { create(:user) }
  let!(:identity) do
    create(:user_oauth_identity, :patreon, user: creator, expires_at: 20.days.from_now,
      scopes: "identity campaigns campaigns.members")
  end
  let(:campaign) { create(:patreon_campaign, user: creator, patreon_id: "camp-1") }

  let(:patron_a) { create(:user) }
  let(:patron_b) { create(:user) }

  before do
    create(:user_oauth_identity, :patreon, user: patron_a, uid: "pa")
    create(:user_oauth_identity, :patreon, user: patron_b, uid: "pb")
  end

  describe "cursor paging" do
    before do
      stub_patreon_campaign_members("camp-1",
        [ { member_id: "m1", user_id: "pa", amount_cents: 300 },
          { member_id: "m2", user_id: "unknown-user", amount_cents: 500 } ],
        next_cursor: "page2")
      stub_patreon_campaign_members("camp-1",
        [ { member_id: "m3", user_id: "pb", amount_cents: 1000, tier_ids: [ "gold" ] } ],
        cursor: "page2")
      described_class.call(campaign)
    end

    it "mirrors linked users from every page and skips strangers", :aggregate_failures do
      expect(campaign.memberships.count).to eq(2)
      expect(patron_a.patreon_memberships.first.entitled_amount_cents).to eq(300)
      expect(patron_b.patreon_memberships.first.entitled_patreon_tier_ids).to eq([ "gold" ])
    end

    it "stamps the reconcile and its source", :aggregate_failures do
      expect(campaign.reload.members_synced_at).to be_present
      expect(patron_b.patreon_memberships.first).to be_source_creator_poll
    end
  end

  it "sweeps active members absent from the full list to former_patron" do
    lapsed = create(:patreon_membership, user: patron_a, patreon_campaign: campaign)
    stub_patreon_campaign_members("camp-1", [])

    described_class.call(campaign)
    expect(lapsed.reload).to be_patron_former_patron
  end

  it "does nothing without the campaigns.members scope" do
    identity.update!(scopes: "identity campaigns")
    expect(described_class.call(campaign)).to be(false)
  end
end
