require "rails_helper"

RSpec.describe SudokupadLinkRefreshJob do
  it "clears links for a puzzle with no published version" do
    puzzle = create(:puzzle, sudokupad_url: "https://sudokupad.app/old")
    described_class.perform_now(puzzle.id)
    expect(puzzle.reload.sudokupad_url).to be_nil
  end

  it "no-ops for a missing puzzle" do
    expect { described_class.perform_now(0) }.not_to raise_error
  end
end
