require "rails_helper"

RSpec.describe FogCellHasher do
  it "pins the wire format shared with the frontend" do
    # The same literal digest is pinned in app/src/utils/fog.test.ts; a
    # mismatch means the two implementations drifted apart and fog would
    # never clear in published play.
    expect(described_class.hashes({ "r0c0" => 5 }, "testsalt")).to eq(
      "r0c0" => "615efe3ec691469e20c5bf7f6f6b8e29ad9193ffb0f9dc8c9da83b91dfca33bc"
    )
  end

  it "hashes every solution cell, each depending on cell and digit", :aggregate_failures do
    hashes = described_class.hashes({ "r0c0" => 1, "r0c1" => 1, "r0c2" => 2 }, "salt")
    expect(hashes.keys).to contain_exactly("r0c0", "r0c1", "r0c2")
    expect(hashes.values.uniq.length).to eq(3)
  end

  it "varies with the salt" do
    a = described_class.hashes({ "r0c0" => 5 }, "salt-a")
    b = described_class.hashes({ "r0c0" => 5 }, "salt-b")
    expect(a["r0c0"]).not_to eq(b["r0c0"])
  end

  it "returns nil for a blank solution or salt", :aggregate_failures do
    expect(described_class.hashes(nil, "salt")).to be_nil
    expect(described_class.hashes({}, "salt")).to be_nil
    expect(described_class.hashes({ "r0c0" => 5 }, nil)).to be_nil
    expect(described_class.hashes({ "r0c0" => 5 }, "")).to be_nil
  end
end
