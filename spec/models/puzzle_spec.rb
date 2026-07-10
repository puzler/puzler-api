require "rails_helper"

RSpec.describe Puzzle, type: :model do
  let(:author) { create(:user) }
  let(:other)  { create(:user) }

  describe "#generate_share_token" do
    it "assigns an unguessable token on create" do
      expect(create(:puzzle).share_token).to be_present
    end
  end

  describe "grid dimension validation" do
    it "accepts gattai-scale grids up to GRID_MAX and rejects beyond", :aggregate_failures do
      expect(build(:puzzle, grid_rows: 48, grid_cols: 48)).to be_valid
      expect(build(:puzzle, grid_rows: 21, grid_cols: 45)).to be_valid
      expect(build(:puzzle, grid_rows: 49, grid_cols: 9)).not_to be_valid
      expect(build(:puzzle, grid_rows: 9, grid_cols: 49)).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:public_puzzle) { create(:puzzle, :published) }
    let!(:container_puzzle) { create(:puzzle, :containers_only) }

    before do
      create(:puzzle, :unlisted)
      create(:puzzle, :access_private)
      create(:puzzle) # draft
    end

    it ".publicly_visible returns only published public puzzles" do
      expect(described_class.publicly_visible).to contain_exactly(public_puzzle)
    end

    it ".container_visible adds the container-only tier to the public ones" do
      expect(described_class.container_visible).to contain_exactly(public_puzzle, container_puzzle)
    end
  end

  describe "#viewable_by?" do
    context "when the puzzle is a draft" do
      let(:puzzle) { create(:puzzle, author:) }

      it "is visible only to the author and admins", :aggregate_failures do
        expect(puzzle.viewable_by?(author)).to be(true)
        expect(puzzle.viewable_by?(create(:user, role: :admin))).to be(true)
        expect(puzzle.viewable_by?(other)).to be(false)
        expect(puzzle.viewable_by?(nil)).to be(false)
      end
    end

    context "when public" do
      let(:puzzle) { create(:puzzle, :published, author:) }

      it "is visible to anyone, signed in or not", :aggregate_failures do
        expect(puzzle.viewable_by?(nil)).to be(true)
        expect(puzzle.viewable_by?(other)).to be(true)
      end
    end

    context "when unlisted" do
      let(:puzzle) { create(:puzzle, :unlisted, author:) }

      it "is visible only with the matching share token", :aggregate_failures do
        expect(puzzle.viewable_by?(other, share_token: puzzle.share_token)).to be(true)
        expect(puzzle.viewable_by?(other, share_token: "wrong")).to be(false)
        expect(puzzle.viewable_by?(other)).to be(false)
      end
    end

    context "when private" do
      let(:puzzle) { create(:puzzle, :access_private, author:) }

      it "is visible only to granted users", :aggregate_failures do
        expect(puzzle.viewable_by?(other)).to be(false)
        puzzle.access_grants.create!(user: other, granted_by: author)
        expect(puzzle.viewable_by?(other)).to be(true)
      end

      it "never leaks via a share token" do
        expect(puzzle.viewable_by?(other, share_token: puzzle.share_token)).to be(false)
      end
    end

    context "when containers_only" do
      let(:puzzle) { create(:puzzle, :containers_only, author:) }

      it "behaves like unlisted for direct access — token gated", :aggregate_failures do
        expect(puzzle.viewable_by?(other, share_token: puzzle.share_token)).to be(true)
        expect(puzzle.viewable_by?(other, share_token: "wrong")).to be(false)
        expect(puzzle.viewable_by?(other)).to be(false)
      end
    end

    context "when a stubbed tier (patrons_only / subscribers_only)" do
      it "denies everyone except the author for now", :aggregate_failures do
        puzzle = create(:puzzle, :published, author:, visibility: :patrons_only)
        expect(puzzle.viewable_by?(other)).to be(false)
        expect(puzzle.viewable_by?(author)).to be(true)
      end
    end
  end

  describe "#recompute_difficulty!" do
    let(:puzzle) { create(:puzzle, :published, author_difficulty: 2) }

    def add_votes(*values)
      values.each { |v| create(:rating, puzzle:, user: create(:user), difficulty_vote: v) }
    end

    it "uses the author's value below the community-vote cutoff", :aggregate_failures do
      add_votes(5, 5, 5) # only 3 votes (< 4)
      puzzle.recompute_difficulty!
      expect(puzzle.difficulty_vote_count).to eq(3)
      expect(puzzle.effective_difficulty).to eq(2) # still the author's value
    end

    it "switches to the community average once the cutoff is reached", :aggregate_failures do
      add_votes(4, 4, 5, 5) # 4 votes, avg 4.5
      puzzle.recompute_difficulty!
      expect(puzzle.avg_difficulty).to eq(4.5)
      expect(puzzle.effective_difficulty).to eq(4.5)
    end

    it "is null when neither the author nor enough votes set it" do
      bare = create(:puzzle, :published)
      bare.recompute_difficulty!
      expect(bare.effective_difficulty).to be_nil
    end
  end
end
