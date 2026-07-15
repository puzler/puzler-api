require "rails_helper"

RSpec.describe "Mutations: patreon", type: :graphql do
  let(:creator) { create(:user) }
  let!(:campaign) { create(:patreon_campaign, user: creator) }

  def bronze
    @bronze ||= create(:patreon_tier, patreon_campaign: campaign, amount_cents: 300)
  end

  def gold
    @gold ||= create(:patreon_tier, patreon_campaign: campaign, amount_cents: 1000)
  end

  def puzzle
    @puzzle ||= create(:puzzle, :published, author: creator, visibility: :patrons_only)
  end

  describe "setPuzzlePatronGate" do
    let(:mutation) do
      <<~GQL
        mutation($id: ID!, $gate: PatronGateInput) {
          setPuzzlePatronGate(input: { id: $id, gate: $gate }) {
            puzzle { patronGate { mode minTier { id } tiers { id } minAmountCents patronsSinceRelease } }
            errors
          }
        }
      GQL
    end

    def set_gate(gate, viewer: creator)
      result = execute_query(mutation, variables: { id: puzzle.id, gate: }, context: auth_context(viewer))
      gql_data(result, "setPuzzlePatronGate")
    end

    it "sets a min_tier gate", :aggregate_failures do
      gate = set_gate({ mode: "MIN_TIER", minTierId: bronze.id, patronsSinceRelease: true })
        .dig("puzzle", "patronGate")
      expect(gate["mode"]).to eq("MIN_TIER")
      expect(gate.dig("minTier", "id")).to eq(bronze.id.to_s)
      expect(gate["patronsSinceRelease"]).to be(true)
    end

    it "sets a multi-tier tier_list gate" do
      gate = set_gate({ mode: "TIER_LIST", tierIds: [ bronze.id, gold.id ] }).dig("puzzle", "patronGate")
      expect(gate["tiers"].map { |t| t["id"] }).to contain_exactly(bronze.id.to_s, gold.id.to_s)
    end

    it "rejects a tier_list with no tiers" do
      expect(set_gate({ mode: "TIER_LIST", tierIds: [] })["errors"])
        .to include("Select at least one of your tiers")
    end

    it "silently drops tiers from someone else's campaign (default gate remains)" do
      gate = set_gate({ mode: "MIN_TIER", minTierId: create(:patreon_tier).id }).dig("puzzle", "patronGate")
      expect(gate["minTier"]).to be_nil
    end

    it "clears back to the default gate with a null gate", :aggregate_failures do
      create(:patron_gate, gateable: puzzle, mode: :min_amount, min_amount_cents: 500)
      expect(set_gate(nil).dig("puzzle", "patronGate")).to be_nil
      expect(puzzle.reload.patron_gate).to be_nil
    end

    it "requires ownership" do
      result = execute_query(mutation,
        variables: { id: puzzle.id, gate: { mode: "MIN_AMOUNT", minAmountCents: 100 } },
        context: auth_context(create(:user)))
      expect(result["errors"]).to be_present
    end
  end

  describe "schedulePuzzleRelease" do
    let(:mutation) do
      <<~GQL
        mutation($id: ID!, $releasedAt: ISO8601DateTime) {
          schedulePuzzleRelease(input: { id: $id, releasedAt: $releasedAt }) {
            puzzle { releasedAt isReleased }
            errors
          }
        }
      GQL
    end

    def schedule(released_at)
      result = execute_query(mutation,
        variables: { id: puzzle.id, releasedAt: released_at }, context: auth_context(creator))
      gql_data(result, "schedulePuzzleRelease", "puzzle")
    end

    it "schedules and clears the release moment", :aggregate_failures do
      time = 2.days.from_now.change(usec: 0)
      data = schedule(time.iso8601)
      expect(data["isReleased"]).to be(false)
      expect(Time.zone.parse(data["releasedAt"])).to eq(time)
      expect(schedule(nil)["isReleased"]).to be(true)
    end
  end

  describe "visibility allowlists" do
    let(:mutation) do
      <<~GQL
        mutation($id: ID!, $visibility: PuzzleVisibilityEnum!) {
          setPuzzleVisibility(input: { id: $id, visibility: $visibility }) {
            puzzle { visibility }
            errors
          }
        }
      GQL
    end

    it "lets a creator set patrons_only" do
      p = create(:puzzle, :published, author: creator)
      result = execute_query(mutation,
        variables: { id: p.id, visibility: "PATRONS_ONLY" }, context: auth_context(creator))
      expect(gql_data(result, "setPuzzleVisibility", "puzzle", "visibility")).to eq("PATRONS_ONLY")
    end

    it "rejects patrons_only for non-creators" do
      plain = create(:user)
      p = create(:puzzle, :published, author: plain)
      result = execute_query(mutation,
        variables: { id: p.id, visibility: "PATRONS_ONLY" }, context: auth_context(plain))
      expect(gql_data(result, "setPuzzleVisibility", "errors")).to include("Unsupported visibility: patrons_only")
    end

    it "rejects patrons_only once the campaign is removed" do
      campaign.update!(status: :removed)
      p = create(:puzzle, :published, author: creator)
      result = execute_query(mutation,
        variables: { id: p.id, visibility: "PATRONS_ONLY" }, context: auth_context(creator))
      expect(gql_data(result, "setPuzzleVisibility", "errors")).to be_present
    end

    it "still allows patrons_only while the token is merely stale" do
      campaign.update!(status: :token_stale)
      p = create(:puzzle, :published, author: creator)
      result = execute_query(mutation,
        variables: { id: p.id, visibility: "PATRONS_ONLY" }, context: auth_context(creator))
      expect(gql_data(result, "setPuzzleVisibility", "puzzle", "visibility")).to eq("PATRONS_ONLY")
    end
  end

  describe "updatePatreonCampaignSettings" do
    let(:mutation) do
      <<~GQL
        mutation($teasers: Boolean!) {
          updatePatreonCampaignSettings(input: { teasersEnabled: $teasers }) {
            campaign { teasersEnabled }
            errors
          }
        }
      GQL
    end

    it "toggles teasers for the campaign owner" do
      result = execute_query(mutation, variables: { teasers: false }, context: auth_context(creator))
      expect(gql_data(result, "updatePatreonCampaignSettings", "campaign", "teasersEnabled")).to be(false)
    end

    it "errors without a campaign" do
      result = execute_query(mutation, variables: { teasers: false }, context: auth_context(create(:user)))
      expect(gql_data(result, "updatePatreonCampaignSettings", "errors")).to include("No linked Patreon campaign")
    end
  end

  describe "self-only user patreon block" do
    let(:query) do
      <<~GQL
        query {
          me {
            patreon {
              campaign { title tiers { title } }
              memberships { campaign { title } patronStatus }
              capabilities { memberships creator }
            }
            hidePatronTeasers
          }
        }
      GQL
    end

    def me_patreon(scopes)
      create(:user_oauth_identity, :patreon, user: creator, scopes:)
      gql_data(execute_query(query, context: auth_context(creator)), "me")
    end

    before do
      bronze
      create(:patreon_membership, user: creator, patreon_campaign: create(:patreon_campaign, title: "Other Campaign"))
    end

    it "exposes campaign, memberships, and capabilities to the owner", :aggregate_failures do
      me = me_patreon("identity identity.memberships campaigns")
      expect(me.dig("patreon", "campaign", "title")).to eq(campaign.title)
      expect(me.dig("patreon", "memberships").first.dig("campaign", "title")).to eq("Other Campaign")
      expect(me.dig("patreon", "capabilities")).to eq({ "memberships" => true, "creator" => true })
      expect(me["hidePatronTeasers"]).to be(false)
    end

    it "reports missing capabilities for pre-feature identities" do
      me = me_patreon("identity")
      expect(me.dig("patreon", "capabilities")).to eq({ "memberships" => false, "creator" => false })
    end

    it "hides the block from other viewers" do
      user_query = "query($username: String!) { user(username: $username) { patreon { campaign { id } } } }"
      result = execute_query(user_query, variables: { username: creator.username },
        context: auth_context(create(:user)))
      expect(gql_data(result, "user", "patreon")).to be_nil
    end
  end

  describe "updateProfileVisibility hidePatronTeasers" do
    it "saves the viewer preference" do
      mutation = <<~GQL
        mutation { updateProfileVisibility(input: { attrs: { hidePatronTeasers: true } }) { user { hidePatronTeasers } errors } }
      GQL
      result = execute_query(mutation, context: auth_context(creator))
      expect(gql_data(result, "updateProfileVisibility", "user", "hidePatronTeasers")).to be(true)
    end
  end
end
