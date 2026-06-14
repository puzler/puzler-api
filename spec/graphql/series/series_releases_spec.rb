require "rails_helper"

RSpec.describe "Series releases", type: :graphql do
  let(:author) { create(:user) }
  let(:viewer) { create(:user) }

  def public_series_with(entryable, released_at:)
    series = create(:series, author:, visibility: :public)
    create(:series_subscription, series:, user: viewer)
    create(:series_entry, series:, entryable:, released_at:)
    series
  end

  describe "scheduleSeriesEntry" do
    let(:mutation) do
      "mutation($e: ID!, $at: ISO8601DateTime) { scheduleSeriesEntry(input: { entryId: $e, releasedAt: $at }) { entry { released releasedAt } errors } }"
    end

    def schedule(entry, at, user = author)
      execute_query(mutation, variables: { e: entry.id, at: }, context: auth_context(user))
    end

    it "marks an entry pending when scheduled in the future" do
      entry = create(:series_entry, series: create(:series, author:), entryable: create(:puzzle))
      data = gql_data(schedule(entry, 1.day.from_now.iso8601), "scheduleSeriesEntry", "entry")
      expect(data["released"]).to be(false)
    end

    it "clears the schedule when released_at is omitted" do
      entry = create(:series_entry, series: create(:series, author:), entryable: create(:puzzle), released_at: 1.day.from_now)
      data = gql_data(schedule(entry, nil), "scheduleSeriesEntry", "entry")
      expect(data["releasedAt"]).to be_nil
    end

    it "does not schedule another author's entry" do
      entry = create(:series_entry, series: create(:series), entryable: create(:puzzle))
      expect(gql_errors(schedule(entry, 1.day.from_now.iso8601)).first["message"]).to eq("Entry not found")
    end
  end

  describe "unreleased entries hidden from non-authors" do
    let(:query) { "query($id: ID!) { series(id: $id) { entries { id } } }" }

    it "omits a future-scheduled entry from a non-author's view" do
      series = public_series_with(create(:puzzle, :published, author:), released_at: 1.hour.from_now)
      data = gql_data(execute_query(query, variables: { id: series.id }, context: auth_context(viewer)), "series")
      expect(data["entries"]).to be_empty
    end
  end

  describe "seriesFeed" do
    let(:query) { "{ seriesFeed { seriesTitle entryType } }" }

    it "lists released public entries from subscribed series, newest first", :aggregate_failures do
      series = public_series_with(create(:puzzle, :published, author:), released_at: 2.days.ago)
      create(:series_entry, series:, entryable: create(:collection, author:, visibility: :public), released_at: 1.hour.ago)
      create(:series_entry, series:, entryable: create(:puzzle, :published, author:), released_at: 1.day.from_now)

      data = gql_data(execute_query(query, context: auth_context(viewer)), "seriesFeed")
      expect(data.map { |e| e["entryType"] }).to eq([ "Collection", "Puzzle" ])
    end

    it "is empty for a user with no subscriptions" do
      expect(gql_data(execute_query(query, context: auth_context(viewer)), "seriesFeed")).to be_empty
    end

    it "requires authentication" do
      expect(gql_errors(execute_query(query)).first["message"]).to eq("Authentication required")
    end
  end
end
