require "rails_helper"

RSpec.describe "Series queries", type: :graphql do
  let(:author) { create(:user) }
  let(:viewer) { create(:user) }

  def add_entry(series, entryable, position)
    create(:series_entry, series:, entryable:, position:)
  end

  describe "series(id:)" do
    let(:query) do
      "query($id: ID!) { series(id: $id) { title entries { entryType } subscribed } }"
    end

    def view(series)
      gql_data(execute_query(query, variables: { id: series.id }, context: auth_context(viewer)), "series")
    end

    it "hides a private series from non-authors" do
      expect(view(create(:series, author:, visibility: :private))).to be_nil
    end

    it "shows only publicly-visible entries to non-authors" do
      expect(view(mixed_series)["entries"].map { |e| e["entryType"] }).to eq([ "Puzzle", "Collection" ])
    end

    context "with container-only entries in a public series" do
      let(:fixture) do
        series = create(:series, author:, visibility: :public)
        collection = create(:collection, author:, visibility: :containers_only)
        puzzle = create(:puzzle, :containers_only, author:)
        add_entry(series, collection, 0)
        add_entry(series, puzzle, 1)
        { series:, collection:, puzzle: }
      end

      def entries(series)
        detail = "query($id: ID!) { series(id: $id) { entries { entryType collection { id shareToken } puzzle { id shareToken } } } }"
        gql_data(execute_query(detail, variables: { id: series.id }, context: auth_context(viewer)), "series", "entries")
      end

      it "surfaces both entries to non-authors (fixing the empty-series bug)" do
        expect(entries(fixture[:series]).map { |e| e["entryType"] }).to eq([ "Collection", "Puzzle" ])
      end

      it "exposes their share tokens so the client can build working links", :aggregate_failures do
        rows = entries(fixture[:series])
        expect(rows[0]["collection"]["shareToken"]).to eq(fixture[:collection].share_token)
        expect(rows[1]["puzzle"]["shareToken"]).to eq(fixture[:puzzle].share_token)
      end
    end

    it "reflects the viewer's subscription state" do
      series = create(:series, author:, visibility: :public)
      create(:series_subscription, series:, user: viewer)
      expect(view(series)["subscribed"]).to be(true)
    end

    # A public series mixing a published puzzle, a draft, a private collection,
    # and a public collection — only the published puzzle and public collection
    # should be visible to a non-author.
    def mixed_series
      series = create(:series, author:, visibility: :public)
      add_entry(series, create(:puzzle, :published, author:), 0)
      add_entry(series, create(:puzzle, author:, status: :draft), 1)
      add_entry(series, create(:collection, author:, visibility: :private), 2)
      add_entry(series, create(:collection, author:, visibility: :public), 3)
      series
    end
  end

  describe "publicSeries (archive connection)" do
    let(:query) do
      "query($f: ListingFilterInput) { publicSeries(filter: $f) { nodes { id } pageInfo { totalCount } } }"
    end

    def archive_ids(**filter)
      result = execute_query(query, variables: { f: filter })
      gql_data(result, "publicSeries", "nodes").map { |s| s["id"] }
    end

    it "returns only public series, hiding private/unlisted ones" do
      public_series = create(:series, visibility: :public)
      create(:series, visibility: :private)
      create(:series, visibility: :unlisted)
      expect(archive_ids).to eq([ public_series.id.to_s ])
    end

    it "searches by title and author", :aggregate_failures do
      setter = create(:user, username: "zelda_sets", display_name: "Zelda")
      mine = create(:series, visibility: :public, author: setter, title: "Killer Marathon")
      create(:series, visibility: :public, title: "Thermo Run")
      expect(archive_ids(search: "killer")).to eq([ mine.id.to_s ])
      expect(archive_ids(search: "zelda_sets")).to eq([ mine.id.to_s ])
    end

    it "filters by setter tier and minimum rating", :aggregate_failures do
      pro = create(:user, setter_tier: :experienced)
      pro_series = create(:series, visibility: :public, author: pro, avg_rating: 4.6)
      create(:series, visibility: :public, avg_rating: 2.0)
      expect(archive_ids(setterTier: "EXPERIENCED")).to eq([ pro_series.id.to_s ])
      expect(archive_ids(minRating: 4.0)).to eq([ pro_series.id.to_s ])
    end

    it "sorts by rating", :aggregate_failures do
      high = create(:series, visibility: :public, avg_rating: 4.8)
      low = create(:series, visibility: :public, avg_rating: 1.2)
      expect(archive_ids(sort: "RATING")).to eq([ high.id.to_s, low.id.to_s ])
    end

    it "paginates with totalCount", :aggregate_failures do
      create_list(:series, 3, visibility: :public)
      result = execute_query(query, variables: { f: { perPage: 2 } })
      expect(gql_data(result, "publicSeries", "nodes").size).to eq(2)
      expect(gql_data(result, "publicSeries", "pageInfo", "totalCount")).to eq(3)
    end
  end

  describe "mySeries / mySubscriptions" do
    let(:mine) { create(:series, author:) }
    let(:followed) { create(:series, visibility: :public) }

    before do
      mine
      create(:series_subscription, series: followed, user: author)
    end

    def ids(field)
      gql_data(execute_query("{ #{field} { id } }", context: auth_context(author)), field).map { |s| s["id"].to_i }
    end

    it "returns the author's own series" do
      # mySeries is a paginated connection; nodes holds the records.
      result = execute_query("{ mySeries { nodes { id } } }", context: auth_context(author))
      expect(gql_data(result, "mySeries", "nodes").map { |s| s["id"].to_i }).to contain_exactly(mine.id)
    end

    it "returns the viewer's subscriptions" do
      expect(ids("mySubscriptions")).to contain_exactly(followed.id)
    end
  end
end
