require "rails_helper"

RSpec.describe "Queries: patron content", type: :graphql do
  let(:creator) { create(:user) }
  let(:patron) { create(:user) }
  let(:outsider) { create(:user) }

  def campaign
    @campaign ||= create(:patreon_campaign, user: creator, title: "Puzzles Weekly",
      url: "https://www.patreon.com/pw")
  end

  def puzzle
    @puzzle ||= create(:puzzle, :published, author: creator, visibility: :patrons_only,
      page_description_html: "<p>secret notes</p>")
  end

  def bronze
    @bronze ||= create(:patreon_tier, patreon_campaign: campaign, patreon_id: "bronze",
      title: "Bronze", amount_cents: 300)
  end

  def gold
    @gold ||= create(:patreon_tier, patreon_campaign: campaign, patreon_id: "gold",
      title: "Gold", amount_cents: 1000)
  end

  def gold_gate!(gateable)
    create(:patron_gate, gateable:, mode: :min_tier, min_tier: gold)
  end

  before do
    create(:user_oauth_identity, :patreon, user: patron)
    create(:user_oauth_identity, :patreon, user: outsider)
    create(:patreon_membership, user: patron, patreon_campaign: campaign, entitled_amount_cents: 300)
    version = create(:puzzle_version, puzzle:, solution_code: "abc")
    puzzle.update!(published_version: version, sudokupad_url: "https://sudokupad.app/xyz")
  end

  describe "teaser mode on puzzle(id:)" do
    let(:query) do
      <<~GQL
        query($id: ID!) {
          puzzle(id: $id) {
            id title
            givenDigits ruleset pageDescriptionHtml sudokupadUrl hasSolutionCode
            publishedVersion { id }
            comments { id }
            patronGate { mode minTier { title } }
            patronAccess { hasAccess lockedReason requiredTierTitle campaignTitle campaignUrl }
          }
        }
      GQL
    end

    def fetch_puzzle(viewer)
      context = viewer ? auth_context(viewer) : {}
      gql_data(execute_query(query, variables: { id: puzzle.id }, context:), "puzzle")
    end

    it "withholds content for non-patrons", :aggregate_failures do
      create(:patron_gate, gateable: puzzle, mode: :min_tier, min_tier: bronze)
      data = fetch_puzzle(outsider)

      expect(data).to include("title" => puzzle.title, "givenDigits" => {}, "ruleset" => {},
        "pageDescriptionHtml" => nil, "sudokupadUrl" => nil, "hasSolutionCode" => false,
        "publishedVersion" => nil, "comments" => [])
    end

    it "keeps the gate marketing copy in the teaser", :aggregate_failures do
      create(:patron_gate, gateable: puzzle, mode: :min_tier, min_tier: bronze)
      data = fetch_puzzle(outsider)
      expect(data.dig("patronGate", "minTier", "title")).to eq("Bronze")
      expect(data["patronAccess"]).to include("hasAccess" => false, "lockedReason" => "NOT_PATRON",
        "requiredTierTitle" => "Bronze", "campaignTitle" => "Puzzles Weekly", "campaignUrl" => "https://www.patreon.com/pw")
    end

    it "teases logged-out viewers too (NOT_LINKED)", :aggregate_failures do
      data = fetch_puzzle(nil)
      expect(data["givenDigits"]).to eq({})
      expect(data["patronAccess"]).to include("hasAccess" => false, "lockedReason" => "NOT_LINKED")
    end

    it "resolves full content for a qualifying patron", :aggregate_failures do
      data = fetch_puzzle(patron)
      expect(data).to include("givenDigits" => puzzle.given_digits, "sudokupadUrl" => "https://sudokupad.app/xyz")
      expect(data["patronAccess"]).to include("hasAccess" => true, "lockedReason" => nil)
    end

    it "resolves full content for the author" do
      expect(fetch_puzzle(creator)["givenDigits"]).to eq(puzzle.given_digits)
    end

    it "returns nil (no teaser) when the creator disabled teasers" do
      campaign.update!(teasers_enabled: false)
      expect(fetch_puzzle(outsider)).to be_nil
    end

    it "still resolves for qualifying patrons when teasers are off" do
      campaign.update!(teasers_enabled: false)
      expect(fetch_puzzle(patron).dig("patronAccess", "hasAccess")).to be(true)
    end

    it "returns nil for unreleased gated puzzles (no pre-announcement leak)" do
      puzzle.update!(released_at: 1.day.from_now)
      expect(fetch_puzzle(patron)).to be_nil
    end

    it "still teases when the viewer opted out of teasers (direct links must not dead-end)" do
      outsider.update!(hide_patron_teasers: true)
      expect(fetch_puzzle(outsider).dig("patronAccess", "hasAccess")).to be(false)
    end
  end

  describe "archive integration" do
    let(:query) do
      <<~GQL
        query($filter: ListingFilterInput) {
          puzzles(filter: $filter) { nodes { id title patronAccess { hasAccess } } }
        }
      GQL
    end

    before do
      create(:puzzle, :published, title: "Public one")
      puzzle
    end

    def archive_titles(viewer, filter: nil)
      result = execute_query(query, variables: { filter: }, context: auth_context(viewer))
      gql_data(result, "puzzles", "nodes").map { |n| n["title"] }
    end

    it "lists patron content for supporters alongside the public archive" do
      expect(archive_titles(patron)).to include("Public one", puzzle.title)
    end

    it "hides patron content from non-supporters entirely" do
      expect(archive_titles(outsider)).to contain_exactly("Public one")
    end

    it "lists locked higher-tier drops as teasers for lower-tier supporters" do
      gold_gate!(puzzle)
      result = execute_query(query, context: auth_context(patron))
      node = gql_data(result, "puzzles", "nodes").find { |n| n["id"] == puzzle.id.to_s }
      expect(node.dig("patronAccess", "hasAccess")).to be(false)
    end

    it "drops locked teasers when the viewer opted out" do
      gold_gate!(puzzle)
      patron.update!(hide_patron_teasers: true)
      expect(archive_titles(patron)).not_to include(puzzle.title)
    end

    it "narrows to patron content only with myStatus PATRON_CONTENT" do
      expect(archive_titles(patron, filter: { myStatus: "PATRON_CONTENT" })).to contain_exactly(puzzle.title)
    end
  end

  describe "patronReleases feed" do
    let(:query) do
      <<~GQL
        query {
          patronReleases {
            ... on Puzzle { id title }
            ... on Collection { id title }
          }
        }
      GQL
    end

    def feed_titles(viewer)
      context = viewer ? auth_context(viewer) : {}
      gql_data(execute_query(query, context:), "patronReleases").map { |n| n["title"] }
    end

    it "returns gated puzzles and collections from supported campaigns, newest release first" do
      puzzle.update!(published_at: 2.days.ago)
      collection = create(:collection, author: creator, visibility: :patrons_only, title: "Pack One")
      collection.update!(created_at: 3.days.ago, released_at: 1.day.ago)

      expect(feed_titles(patron)).to eq([ "Pack One", puzzle.title ])
    end

    it "hides scheduled releases until the moment passes, no job required", :aggregate_failures do
      puzzle.update!(released_at: 1.hour.from_now)
      expect(feed_titles(patron)).to eq([])

      puzzle.update!(released_at: 1.minute.ago)
      expect(feed_titles(patron)).to eq([ puzzle.title ])
    end

    it "is empty for guests and non-supporters", :aggregate_failures do
      puzzle
      expect(feed_titles(nil)).to eq([])
      expect(feed_titles(outsider)).to eq([])
    end
  end

  describe "collection teaser mode" do
    let(:query) do
      <<~GQL
        query($id: ID!) {
          collection(id: $id) {
            id title pageDescriptionHtml
            entries { id }
            patronAccess { hasAccess lockedReason }
          }
        }
      GQL
    end

    before { create(:collection_entry, collection:, puzzle: create(:puzzle, :published, author: creator)) }

    def collection
      @collection ||= create(:collection, author: creator, visibility: :patrons_only,
        page_description_html: "<p>pack notes</p>")
    end

    def fetch_collection(viewer)
      gql_data(execute_query(query, variables: { id: collection.id }, context: auth_context(viewer)), "collection")
    end

    it "withholds entries and body for non-patrons", :aggregate_failures do
      data = fetch_collection(outsider)
      expect(data).to include("title" => collection.title, "entries" => [], "pageDescriptionHtml" => nil)
      expect(data["patronAccess"]).to include("hasAccess" => false, "lockedReason" => "NOT_PATRON")
    end

    it "resolves entries for qualifying patrons" do
      expect(fetch_collection(patron)["entries"].size).to eq(1)
    end
  end

  describe "patron-locked rows inside an accessible collection" do
    let(:query) do
      <<~GQL
        query($id: ID!) {
          collection(id: $id) {
            entries { patronLocked puzzle { id title givenDigits } }
          }
        }
      GQL
    end

    before do
      gold_gate!(gated)
      create(:collection_entry, collection:, puzzle: create(:puzzle, :published, author: creator), position: 0)
      create(:collection_entry, collection:, puzzle: gated, position: 1)
    end

    def collection
      @collection ||= create(:collection, author: creator, visibility: :public)
    end

    def gated
      @gated ||= create(:puzzle, :published, author: creator, visibility: :patrons_only)
    end

    def fetch_entries(viewer)
      gql_data(execute_query(query, variables: { id: collection.id }, context: auth_context(viewer)),
        "collection", "entries")
    end

    it "marks member puzzles above the viewer's tier as locked teaser rows", :aggregate_failures do
      entries = fetch_entries(patron)
      locked = entries.find { |e| e["patronLocked"] }

      expect(entries.size).to eq(2)
      expect(locked.dig("puzzle", "id")).to eq(gated.id.to_s)
      expect(locked.dig("puzzle", "givenDigits")).to eq({})
    end

    it "omits gated rows entirely for viewers who opted out of teasers" do
      patron.update!(hide_patron_teasers: true)
      expect(fetch_entries(patron).size).to eq(1)
    end
  end

  describe "patron_satisfiable_ids parity with PatronAccess" do
    def gated_puzzle(**attrs)
      create(:puzzle, :published, author: creator, visibility: :patrons_only, **attrs)
    end

    def parity_fixtures
      {
        default: gated_puzzle,
        min_tier: gated_puzzle.tap { |p| create(:patron_gate, gateable: p, mode: :min_tier, min_tier: bronze) },
        tier_list: gated_puzzle.tap { |p| tier_list_gate!(p) },
        min_amount: gated_puzzle.tap { |p| create(:patron_gate, gateable: p, mode: :min_amount, min_amount_cents: 500) },
        backlog: gated_puzzle(published_at: 2.years.ago).tap { |p| create(:patron_gate, gateable: p, patrons_since_release: true) }
      }
    end

    def tier_list_gate!(gateable)
      gate = build(:patron_gate, gateable:, mode: :tier_list)
      gate.gate_tiers.build(patreon_tier: gold)
      gate.save!
    end

    it "agrees across every gate mode" do
      fixtures = parity_fixtures
      sql_ids = Puzzle.where(id: Puzzle.patron_satisfiable_ids(patron)).pluck(:id).to_set
      access = PatronAccess.new(patron)

      expect(fixtures.values.map { |p| sql_ids.include?(p.id) }).to eq(fixtures.values.map { |p| access.satisfies?(p) })
    end
  end
end
