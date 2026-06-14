require "rails_helper"

RSpec.describe "Series mutations", type: :graphql do
  let(:user) { create(:user) }

  def gql(mutation, vars, ctx = nil)
    execute_query(mutation, variables: vars, context: ctx || auth_context(user))
  end

  def entry(type, position)
    { "entryType" => type, "position" => position }
  end

  describe "createSeries" do
    let(:mutation) do
      "mutation($title: String!, $visibility: SeriesVisibilityEnum) { createSeries(input: { title: $title, visibility: $visibility }) { series { id title visibility } errors } }"
    end

    it "creates a private series by default", :aggregate_failures do
      data = gql_data(gql(mutation, { title: "Weekly" }), "createSeries")
      expect(data["errors"]).to be_empty
      expect(data["series"]).to include("title" => "Weekly", "visibility" => "PRIVATE")
    end

    it "rejects a stubbed visibility tier", :aggregate_failures do
      data = gql_data(gql(mutation, { title: "X", visibility: "PATRONS_ONLY" }), "createSeries")
      expect(data["series"]).to be_nil
      expect(data["errors"].first).to include("Unsupported visibility")
    end

    it "requires authentication" do
      expect(gql_errors(gql(mutation, { title: "X" }, {})).first["message"]).to eq("Authentication required")
    end
  end

  describe "addSeriesEntry" do
    let(:mutation) do
      "mutation($s: ID!, $t: String!, $i: ID!) { addSeriesEntry(input: { seriesId: $s, entryableType: $t, entryableId: $i }) { series { entries { entryType position } } errors } }"
    end

    let(:series) { create(:series, author: user) }

    it "appends puzzles and collections in order and is idempotent", :aggregate_failures do
      puzzle = create(:puzzle, author: user)
      2.times { gql(mutation, { s: series.id, t: "Puzzle", i: puzzle.id }) }
      data = gql_data(gql(mutation, { s: series.id, t: "Collection", i: create(:collection, author: user).id }), "addSeriesEntry", "series")
      expect(data["entries"]).to eq([ entry("Puzzle", 0), entry("Collection", 1) ])
    end

    it "does not add another author's puzzle" do
      message = gql_errors(gql(mutation, { s: series.id, t: "Puzzle", i: create(:puzzle).id })).first["message"]
      expect(message).to eq("Puzzle not found")
    end
  end

  describe "reorderSeriesEntries" do
    let(:mutation) do
      "mutation($s: ID!, $ids: [ID!]!) { reorderSeriesEntries(input: { seriesId: $s, orderedEntryIds: $ids }) { series { entries { id position } } errors } }"
    end

    it "sets positions by array index" do
      series = create(:series, author: user)
      a = create(:series_entry, series:, entryable: create(:puzzle), position: 0)
      b = create(:series_entry, series:, entryable: create(:puzzle), position: 1)
      data = gql_data(gql(mutation, { s: series.id, ids: [ b.id, a.id ] }), "reorderSeriesEntries", "series")
      expect(data["entries"].map { |e| e["id"].to_i }).to eq([ b.id, a.id ])
    end
  end

  describe "removeSeriesEntry" do
    let(:mutation) { "mutation($e: ID!) { removeSeriesEntry(input: { entryId: $e }) { series { entryCount } errors } }" }

    it "removes an entry from the author's series" do
      series = create(:series, author: user)
      entry = create(:series_entry, series:, entryable: create(:puzzle))
      data = gql_data(gql(mutation, { e: entry.id }), "removeSeriesEntry", "series")
      expect(data["entryCount"]).to eq(0)
    end

    it "does not remove an entry from another author's series" do
      entry = create(:series_entry, entryable: create(:puzzle))
      expect(gql_errors(gql(mutation, { e: entry.id })).first["message"]).to eq("Entry not found")
    end
  end

  describe "toggleSeriesSubscription" do
    let(:mutation) { "mutation($s: ID!) { toggleSeriesSubscription(input: { seriesId: $s }) { subscribed subscriberCount } }" }

    it "subscribes then unsubscribes a visible series", :aggregate_failures do
      series = create(:series, visibility: :public)
      on = gql_data(gql(mutation, { s: series.id }), "toggleSeriesSubscription")
      expect(on).to eq("subscribed" => true, "subscriberCount" => 1)
      off = gql_data(gql(mutation, { s: series.id }), "toggleSeriesSubscription")
      expect(off).to eq("subscribed" => false, "subscriberCount" => 0)
    end

    it "does not subscribe to a private series the user cannot see" do
      series = create(:series, visibility: :private)
      expect(gql_errors(gql(mutation, { s: series.id })).first["message"]).to eq("Series not found")
    end
  end
end
