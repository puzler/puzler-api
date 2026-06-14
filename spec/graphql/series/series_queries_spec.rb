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
      expect(ids("mySeries")).to contain_exactly(mine.id)
    end

    it "returns the viewer's subscriptions" do
      expect(ids("mySubscriptions")).to contain_exactly(followed.id)
    end
  end
end
