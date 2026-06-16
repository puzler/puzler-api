require "rails_helper"

RSpec.describe Collection, type: :model do
  let(:author) { create(:user) }
  let(:other) { create(:user) }

  it "generates an unguessable share token on create" do
    expect(create(:collection).share_token).to be_present
  end

  describe ".publicly_visible" do
    it "returns only public collections", :aggregate_failures do
      pub = create(:collection, visibility: :public)
      create(:collection, visibility: :private)
      create(:collection, visibility: :unlisted)
      expect(described_class.publicly_visible).to contain_exactly(pub)
    end
  end

  describe "#viewable_by?" do
    it "is visible only to author/admin when private", :aggregate_failures do
      c = create(:collection, author:, visibility: :private)
      expect(c.viewable_by?(author)).to be(true)
      expect(c.viewable_by?(create(:user, role: :admin))).to be(true)
      expect(c.viewable_by?(other)).to be(false)
      expect(c.viewable_by?(nil)).to be(false)
    end

    it "is visible to anyone when public" do
      expect(create(:collection, visibility: :public).viewable_by?(nil)).to be(true)
    end

    it "needs the matching share token when unlisted", :aggregate_failures do
      c = create(:collection, visibility: :unlisted)
      expect(c.viewable_by?(other, share_token: c.share_token)).to be(true)
      expect(c.viewable_by?(other, share_token: "wrong")).to be(false)
      expect(c.viewable_by?(other)).to be(false)
    end
  end

  describe "ordered membership" do
    let(:collection) { create(:collection) }
    let(:first) { create(:puzzle) }
    let(:second) { create(:puzzle) }

    it "returns puzzles by position" do
      create(:collection_puzzle, collection:, puzzle: second, position: 1)
      create(:collection_puzzle, collection:, puzzle: first, position: 0)
      expect(collection.reload.puzzles.pluck(:id)).to eq([ first.id, second.id ])
    end

    it "lets a puzzle live in several collections at once" do
      create(:collection_puzzle, collection:, puzzle: first)
      create(:collection_puzzle, puzzle: first)
      expect(first.collections.count).to eq(2)
    end
  end

  describe "#recompute_aggregates!" do
    let(:collection) { create(:collection) }

    it "averages member ratings and sums member solves" do
      create(:collection_puzzle, collection:, puzzle: create(:puzzle, avg_rating: 4.0, solve_count: 10))
      create(:collection_puzzle, collection:, puzzle: create(:puzzle, avg_rating: 2.0, solve_count: 5))
      collection.recompute_aggregates!
      expect([ collection.avg_rating, collection.solve_count ]).to eq([ 3.0, 15 ])
    end

    it "cascades to any series containing the collection" do
      series = create(:series)
      create(:series_entry, series:, entryable: collection)
      create(:collection_puzzle, collection:, puzzle: create(:puzzle, solve_count: 7))
      collection.recompute_aggregates!
      expect(series.reload.solve_count).to eq(7)
    end
  end
end
