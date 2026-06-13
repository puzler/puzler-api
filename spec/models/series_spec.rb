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

  describe "subscriptions" do
    it "tracks subscribers and blocks duplicates", :aggregate_failures do
      series = create(:series)
      create(:series_subscription, series:, user: other)
      expect(series.subscribers).to contain_exactly(other)
      dup = build(:series_subscription, series:, user: other)
      expect(dup).not_to be_valid
    end
  end
end
