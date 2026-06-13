require "rails_helper"

RSpec.describe PuzzleVersion, type: :model do
  let(:puzzle) { create(:puzzle) }

  describe "version numbering" do
    it "auto-assigns sequential version numbers per puzzle" do
      v1 = create(:puzzle_version, puzzle:)
      v2 = create(:puzzle_version, puzzle:)
      v3 = create(:puzzle_version, puzzle:)
      expect([ v1.version_number, v2.version_number, v3.version_number ]).to eq([ 1, 2, 3 ])
    end

    it "numbers independently across puzzles" do
      other = create(:puzzle)
      create(:puzzle_version, puzzle:)
      first_on_other = create(:puzzle_version, puzzle: other)
      expect(first_on_other.version_number).to eq(1)
    end

    it "continues numbering after a version is deleted" do
      create(:puzzle_version, puzzle:)
      create(:puzzle_version, puzzle:).destroy
      expect(create(:puzzle_version, puzzle:).version_number).to eq(3)
    end
  end

  describe "#display_name" do
    it "falls back to v{n} when unlabeled" do
      expect(create(:puzzle_version, puzzle:, label: nil).display_name).to eq("v1")
    end

    it "uses the label when present" do
      expect(create(:puzzle_version, puzzle:, label: "Final").display_name).to eq("Final")
    end
  end

  describe "#published?" do
    it "is true only for the puzzle's published version", :aggregate_failures do
      v1 = create(:puzzle_version, puzzle:)
      v2 = create(:puzzle_version, puzzle:)
      puzzle.update!(published_version: v2)
      expect(v1.reload.published?).to be(false)
      expect(v2.reload.published?).to be(true)
    end
  end

  describe "destroying a puzzle" do
    it "destroys its versions and nullifies the published pointer without FK errors" do
      version = create(:puzzle_version, puzzle:)
      puzzle.update!(published_version: version)
      expect { puzzle.destroy! }.to change(described_class, :count).by(-1)
    end
  end
end
