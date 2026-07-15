require "rails_helper"

RSpec.describe PatronAccess do
  let(:creator) { create(:user) }
  let(:campaign) { create(:patreon_campaign, user: creator) }
  let(:patron) { create(:user) }
  let(:puzzle) { create(:puzzle, :published, author: creator, visibility: :patrons_only) }

  def bronze
    @bronze ||= create(:patreon_tier, patreon_campaign: campaign, patreon_id: "bronze", amount_cents: 300)
  end

  def gold
    @gold ||= create(:patreon_tier, patreon_campaign: campaign, patreon_id: "gold", amount_cents: 1000)
  end

  before { create(:user_oauth_identity, :patreon, user: patron) }

  def membership(**attrs)
    create(:patreon_membership, { user: patron, patreon_campaign: campaign }.merge(attrs))
  end

  describe "default gate (no gate row)" do
    it "passes any active patron with a nonzero pledge" do
      membership(entitled_amount_cents: 100)
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end

    it "passes an active patron with an entitled tier but zero amount" do
      membership(entitled_amount_cents: 0, entitled_patreon_tier_ids: [ "bronze" ])
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end

    it "rejects free members (active, no tier, zero amount)" do
      membership(entitled_amount_cents: 0)
      expect(described_class.new(patron).satisfies?(puzzle)).to be false
    end

    it "rejects former and declined patrons" do
      membership(patron_status: :former_patron, entitled_amount_cents: 500)
      expect(described_class.new(patron).satisfies?(puzzle)).to be false
    end
  end

  describe "min_tier mode" do
    before { create(:patron_gate, gateable: puzzle, mode: :min_tier, min_tier: bronze) }

    it "passes a patron entitled to the tier" do
      membership(entitled_amount_cents: 0, entitled_patreon_tier_ids: [ "bronze" ])
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end

    it "passes a custom-pledge patron via the amount fallback (empty entitled tiers)" do
      membership(entitled_amount_cents: 450, entitled_patreon_tier_ids: [])
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end

    it "passes a higher-tier patron whose pledge exceeds the minimum" do
      membership(entitled_amount_cents: 1000, entitled_patreon_tier_ids: [ "gold" ])
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end

    it "rejects a patron below the tier price with no tier match" do
      membership(entitled_amount_cents: 100, entitled_patreon_tier_ids: [])
      expect(described_class.new(patron).satisfies?(puzzle)).to be false
    end

    it "keeps working off the recorded price when the min tier was discarded on Patreon" do
      bronze.discard!
      membership(entitled_amount_cents: 300, entitled_patreon_tier_ids: [])
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end
  end

  describe "tier_list mode" do
    before do
      gate = build(:patron_gate, gateable: puzzle, mode: :tier_list)
      gate.gate_tiers.build(patreon_tier: bronze)
      gate.gate_tiers.build(patreon_tier: gold)
      gate.save!
    end

    it "passes when entitled to any selected tier" do
      membership(entitled_patreon_tier_ids: [ "gold" ])
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end

    it "rejects custom pledges strictly (no amount fallback)" do
      membership(entitled_amount_cents: 5000, entitled_patreon_tier_ids: [])
      expect(described_class.new(patron).satisfies?(puzzle)).to be false
    end
  end

  describe "min_amount mode" do
    before { create(:patron_gate, gateable: puzzle, mode: :min_amount, min_amount_cents: 500) }

    it "gates purely on the pledge amount" do
      membership(entitled_amount_cents: 500)
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end

    it "rejects below the threshold even with an entitled tier" do
      membership(entitled_amount_cents: 300, entitled_patreon_tier_ids: [ "bronze" ])
      expect(described_class.new(patron).satisfies?(puzzle)).to be false
    end
  end

  describe "back-catalog lock (patrons_since_release)" do
    before do
      puzzle.update!(published_at: 2.months.ago)
      create(:patron_gate, gateable: puzzle, mode: :min_tier, min_tier: nil, patrons_since_release: true)
    end

    it "passes a patron whose pledge predates the release" do
      membership(entitled_amount_cents: 300, pledge_relationship_start: 3.months.ago)
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end

    it "rejects a patron who joined after the release" do
      membership(entitled_amount_cents: 300, pledge_relationship_start: 1.week.ago)
      expect(described_class.new(patron).satisfies?(puzzle)).to be false
    end

    it "passes a re-joined patron via first_active_at even though Patreon reset their pledge start" do
      membership(entitled_amount_cents: 300,
        pledge_relationship_start: 1.week.ago, first_active_at: 6.months.ago)
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end

    it "anchors on released_at when the release was scheduled" do
      puzzle.update!(released_at: 1.day.ago)
      membership(entitled_amount_cents: 300, pledge_relationship_start: 1.week.ago)
      expect(described_class.new(patron).satisfies?(puzzle)).to be true
    end

    it "rejects when no join date is known at all" do
      membership(entitled_amount_cents: 300)
      expect(described_class.new(patron).satisfies?(puzzle)).to be false
    end
  end

  describe "#locked_reason" do
    it "returns creator_unavailable when the author has no campaign" do
      orphan = create(:puzzle, :published, visibility: :patrons_only)
      expect(described_class.new(patron).locked_reason(orphan)).to eq(:creator_unavailable)
    end

    it "returns creator_unavailable when the campaign was removed on Patreon" do
      campaign.update!(status: :removed)
      expect(described_class.new(patron).locked_reason(puzzle)).to eq(:creator_unavailable)
    end

    it "returns not_linked for guests and users without a Patreon identity", :aggregate_failures do
      campaign
      expect(described_class.new(nil).locked_reason(puzzle)).to eq(:not_linked)
      expect(described_class.new(create(:user)).locked_reason(puzzle)).to eq(:not_linked)
    end

    it "returns not_patron when linked but not a member" do
      campaign
      expect(described_class.new(patron).locked_reason(puzzle)).to eq(:not_patron)
    end

    it "returns declined for payment-declined patrons" do
      membership(patron_status: :declined_patron)
      expect(described_class.new(patron).locked_reason(puzzle)).to eq(:declined)
    end

    it "returns insufficient_tier when active but below the gate" do
      create(:patron_gate, gateable: puzzle, mode: :min_amount, min_amount_cents: 1000)
      membership(entitled_amount_cents: 300)
      expect(described_class.new(patron).locked_reason(puzzle)).to eq(:insufficient_tier)
    end

    it "returns joined_after_release when only the back-catalog check fails" do
      puzzle.update!(published_at: 2.months.ago)
      create(:patron_gate, gateable: puzzle, patrons_since_release: true)
      membership(entitled_amount_cents: 300, pledge_relationship_start: 1.week.ago)
      expect(described_class.new(patron).locked_reason(puzzle)).to eq(:joined_after_release)
    end
  end

  it "loads memberships once across many checks" do
    membership(entitled_amount_cents: 300)
    other = create(:puzzle, :published, author: creator, visibility: :patrons_only)
    access = described_class.new(patron)
    access.satisfies?(puzzle)

    # Memberships are memoized; only the (unpreloaded) association walks hit SQL.
    expect(count_queries { access.satisfies?(other) }).to be <= 3
  end

  def count_queries(&)
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    queries
  end
end
