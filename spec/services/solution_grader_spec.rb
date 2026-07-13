require "rails_helper"

RSpec.describe SolutionGrader do
  let(:puzzle)  { create(:puzzle, :published) }
  # Factory solution is { "r0c0" => 5, "r0c1" => 3 }.
  let!(:version) { create(:puzzle_version, puzzle:).tap { |v| puzzle.update!(published_version: v) } }

  describe ".result" do
    it "grades against the published version's solution" do
      expect(described_class.result(puzzle, { "r0c0" => 5, "r0c1" => 3 })).to eq(SolutionGrader::SOLVED)
    end

    it "returns CORRECT_SO_FAR for a partial board with no mistakes" do
      expect(described_class.result(puzzle, { "r0c0" => 5 })).to eq(SolutionGrader::CORRECT_SO_FAR)
    end

    it "returns INCORRECT for a wrong digit or one placed where the solution is blank", :aggregate_failures do
      expect(described_class.result(puzzle, { "r0c0" => 9, "r0c1" => 3 })).to eq(SolutionGrader::INCORRECT)
      expect(described_class.result(puzzle, { "r0c0" => 5, "r0c1" => 3, "r5c5" => 1 })).to eq(SolutionGrader::INCORRECT)
    end

    it "coerces string digits and unwraps { value: } hashes" do
      expect(described_class.result(puzzle, { "r0c0" => "5", "r0c1" => { "value" => 3 } })).to eq(SolutionGrader::SOLVED)
    end

    it "ignores zero and nil entries (permissive entry)" do
      expect(described_class.result(puzzle, { "r0c0" => 5, "r0c1" => 3, "r8c8" => 0, "r7c7" => nil }))
        .to eq(SolutionGrader::SOLVED)
    end

    it "returns INCORRECT when there is no published version" do
      puzzle.update!(published_version: nil)
      expect(described_class.result(puzzle, { "r0c0" => 5, "r0c1" => 3 })).to eq(SolutionGrader::INCORRECT)
    end

    it "returns INCORRECT when the published version has no solution" do
      version.update!(solution: {})
      expect(described_class.result(puzzle, { "r0c0" => 5 })).to eq(SolutionGrader::INCORRECT)
    end
  end

  describe ".correct?" do
    it "is true only for a complete, correct board", :aggregate_failures do
      expect(described_class.correct?(puzzle, { "r0c0" => 5, "r0c1" => 3 })).to be(true)
      expect(described_class.correct?(puzzle, { "r0c0" => 5 })).to be(false)
      expect(described_class.correct?(puzzle, { "r0c0" => 9, "r0c1" => 3 })).to be(false)
    end
  end
end
