require "rails_helper"

RSpec.describe Series, type: :model do
  let(:author) { create(:user) }
  let(:other) { create(:user) }

  it "generates an unguessable share token on create" do
    expect(create(:series).share_token).to be_present
  end

  describe ".publicly_visible" do
    it "returns only public series", :aggregate_failures do
      pub = create(:series, visibility: :public)
      create(:series, visibility: :private)
      create(:series, visibility: :unlisted)
      expect(described_class.publicly_visible).to contain_exactly(pub)
    end
  end

  describe "#viewable_by?" do
    it "is visible only to author/admin when private", :aggregate_failures do
      s = create(:series, author:, visibility: :private)
      expect(s.viewable_by?(author)).to be(true)
      expect(s.viewable_by?(create(:user, role: :admin))).to be(true)
      expect(s.viewable_by?(other)).to be(false)
      expect(s.viewable_by?(nil)).to be(false)
    end

    it "is visible to anyone when public" do
      expect(create(:series, visibility: :public).viewable_by?(nil)).to be(true)
    end

    it "needs the matching share token when unlisted", :aggregate_failures do
      s = create(:series, visibility: :unlisted)
      expect(s.viewable_by?(other, share_token: s.share_token)).to be(true)
      expect(s.viewable_by?(other, share_token: "wrong")).to be(false)
      expect(s.viewable_by?(other)).to be(false)
    end
  end

  describe "polymorphic ordered entries" do
    let(:series) { create(:series) }

    it "holds both puzzles and collections, ordered by position" do
      puzzle = create(:puzzle)
      collection = create(:collection)
      create(:series_entry, series:, entryable: collection, position: 1)
      create(:series_entry, series:, entryable: puzzle, position: 0)
      expect(series.reload.series_entries.map(&:entryable)).to eq([ puzzle, collection ])
    end

    it "removes its entries when destroyed but keeps the targets", :aggregate_failures do
      puzzle = create(:puzzle)
      create(:series_entry, series:, entryable: puzzle)
      expect { series.destroy }.to change(SeriesEntry, :count).by(-1)
      expect(Puzzle.exists?(puzzle.id)).to be(true)
    end
  end

  describe "entry release scheduling" do
    let(:series) { create(:series) }

    it "treats a nil or past released_at as released and a future one as pending", :aggregate_failures do
      immediate = create(:series_entry, series:, entryable: create(:puzzle), released_at: nil)
      past = create(:series_entry, series:, entryable: create(:puzzle), released_at: 1.hour.ago)
      future = create(:series_entry, series:, entryable: create(:puzzle), released_at: 1.hour.from_now)
      expect([ immediate.released?, past.released?, future.released? ]).to eq([ true, true, false ])
      expect(SeriesEntry.released).to contain_exactly(immediate, past)
    end
  end

  describe "subscriptions" do
    it "tracks subscribers and blocks duplicates", :aggregate_failures do
      series = create(:series)
      create(:series_subscription, series:, user: other)
      expect(series.subscribers).to contain_exactly(other)
      dup = build(:series_subscription, series:, user: other)
      expect(dup).not_to be_valid
    end
  end

  describe "#recompute_aggregates!" do
    let(:series) { create(:series) }

    it "rolls up direct puzzle entries", :aggregate_failures do
      create(:series_entry, series:, entryable: create(:puzzle, avg_rating: 4.0, solve_count: 10))
      create(:series_entry, series:, entryable: create(:puzzle, avg_rating: 2.0, solve_count: 5))
      series.recompute_aggregates!
      expect(series.avg_rating).to eq(3.0)
      expect(series.solve_count).to eq(15)
    end

    it "rolls up puzzles nested inside entered collections" do
      collection = create(:collection)
      create(:collection_puzzle, collection:, puzzle: create(:puzzle, solve_count: 8))
      create(:series_entry, series:, entryable: collection)
      series.recompute_aggregates!
      expect(series.solve_count).to eq(8)
    end

    context "when a puzzle is reachable directly and via a collection" do
      let(:puzzle) { create(:puzzle, avg_rating: 5.0, solve_count: 3) }
      let(:collection) { create(:collection) }

      before do
        create(:collection_puzzle, collection:, puzzle:)
        create(:series_entry, series:, entryable: collection)
        create(:series_entry, series:, entryable: puzzle)
      end

      it "counts that puzzle only once" do
        series.recompute_aggregates!
        expect([ series.solve_count, series.avg_rating ]).to eq([ 3, 5.0 ])
      end
    end
  end
end
