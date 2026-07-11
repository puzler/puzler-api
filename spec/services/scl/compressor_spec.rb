require "rails_helper"

RSpec.describe Scl::Compressor do
  it "prefixes the payload with scl" do
    expect(described_class.compress({ "a" => 1 })).to start_with("scl")
  end

  it "round-trips a hash through compress/decompress" do
    data = { "cellSize" => 64, "cells" => [ [ {} ] ], "cages" => [ { "value" => "title: x" } ] }
    expect(described_class.decompress(described_class.compress(data))).to eq(data)
  end

  it "keeps leading zeros in solution meta-cages (why we skip PuzzleZipper)" do
    data = { "cages" => [ { "value" => "solution: 0123" } ] }
    round = described_class.decompress(described_class.compress(data))
    expect(round.dig("cages", 0, "value")).to eq("solution: 0123")
  end

  # Guards that the gem stays byte-compatible with SudokuPad's own compressor —
  # this exact payload was produced by loadFPuzzle.compressPuzzle in the live
  # sudokupad.app (v0.611.0) console for the same object.
  it "matches SudokuPad's compressPuzzle byte-for-byte" do
    expect(described_class.compress(parity_fixture)).to eq("scl#{parity_js_payload}")
  end

  def parity_js_payload
    "N4IgxgpgNlDKCWAvCIBcA2ALAGnNKAzmgNrGgBuAhlAK4qoCMuA5vORAHZoAuATnQF9swAQF1sZISNHiQvCKwD2HIqlLEADNg3jN2BrqY6JTAzNxhKzCKrIgqteiG7xuUCKgAEABUq9XAJ4gUvbUdGggBIq0LspeGgwATADMwbJQ8Bw2JKAA7pQB3oqZ3LaaAHQArNpVhlX6tbJg0Yq8EQDEAGadGr0aILjcABbwYADWWQSqSWICQA=="
  end

  def parity_fixture
    {
      "cellSize" => 64,
      "cells" => [ [ { "value" => 1, "given" => true }, {} ], [ {}, {} ] ],
      "regions" => [ [ [ 0, 0 ], [ 0, 1 ], [ 1, 0 ], [ 1, 1 ] ] ],
      "cages" => [ { "value" => "title: Parity" }, { "value" => "solution: 0123" } ],
      "lines" => [ { "wayPoints" => [ [ 0.5, 0.5 ], [ 1.5, 1.5 ] ], "color" => "#ff0000", "thickness" => 12 } ]
    }
  end
end
