require "rails_helper"

RSpec.describe ConstraintTypeExtractor do
  let(:definition) do
    {
      "activeConstraints" => [ { "type" => "thermometer" }, { "type" => "arrow" }, { "type" => "thermometer" } ],
      "globals" => { "variants" => [ "knights_move", "diagonal_positive" ], "custom" => [ { "type" => "anti_ratio" } ] }
    }
  end

  it "returns an empty array for blank input", :aggregate_failures do
    expect(described_class.extract(nil)).to eq([])
    expect(described_class.extract({})).to eq([])
  end

  it "collects active-constraint, global-variant, and custom-global types, sorted and deduped" do
    expect(described_class.extract(definition)).to eq(%w[anti_ratio arrow diagonal_positive knights_move thermometer])
  end

  it "tolerates symbol keys and missing sections" do
    expect(described_class.extract({ activeConstraints: [ { type: "renban" } ] })).to eq([ "renban" ])
  end
end
