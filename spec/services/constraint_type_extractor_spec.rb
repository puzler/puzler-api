require "rails_helper"

RSpec.describe ConstraintTypeExtractor do
  it "returns an empty array for blank input", :aggregate_failures do
    expect(described_class.extract(nil)).to eq([])
    expect(described_class.extract({})).to eq([])
  end

  context "with a pre-v4 definition (activeConstraints present)" do
    let(:definition) do
      {
        "activeConstraints" => [ { "type" => "thermometer" }, { "type" => "arrow" }, { "type" => "thermometer" } ],
        "globals" => { "variants" => [ "knights_move", "positive_diagonal" ], "custom" => [ { "type" => "anti_ratio", "value" => 2 } ] }
      }
    end

    it "collects types through the v4 migrator, adding variant group chips, sorted and deduped" do
      expect(described_class.extract(definition))
        .to eq(%w[anti_kropki anti_ratio arrow chess diagonals knights_move positive_diagonal sudoku_rules thermometer])
    end

    it "tolerates symbol keys and missing sections" do
      expect(described_class.extract({ activeConstraints: [ { type: "renban" } ] })).to eq(%w[renban sudoku_rules])
    end
  end

  context "with a v4 document" do
    let(:definition) do
      {
        "formatVersion" => 4,
        "grid" => { "rows" => 9, "cols" => 9 },
        "constraints" => {
          "thermometers" => [ { "bulb" => "r1c1", "lines" => [] } ],
          "xSums" => [],
          "notARealKey" => []
        },
        "globals" => {
          "antiXv" => { "x" => true, "sums" => [ 12 ] },
          "disjointSets" => { "enabled" => true },
          "chess" => {}
        },
        "cosmetics" => {
          "lines" => [], "linePresets" => [ { "id" => "line-1" } ],
          "cellColors" => { "r1c6" => "color-1" }, "cellColorPresets" => []
        }
      }
    end

    it "collects chip types from constraint keys, cosmetic kinds, and globals groups" do
      expect(described_class.extract(definition)).to eq(
        %w[anti_sum anti_x anti_xv cell_color chess cosmetic_line disjoint_sets thermometer x_sums]
      )
    end

    it "tags fog from the globals group and fog lights from their constraint key" do
      expect(described_class.extract(
        "formatVersion" => 4,
        "globals" => { "fog" => { "enabled" => true } },
        "constraints" => { "fogLights" => [ "r1c1" ] }
      )).to eq(%w[fog fog_lights])
    end

    it "ignores unknown keys, preset keys, disabled toggles, and empty custom lists", :aggregate_failures do
      expect(described_class.extract(definition)).not_to include("notARealKey")
      expect(described_class.extract(
        "formatVersion" => 4,
        "globals" => { "antiKropki" => { "white" => false, "differences" => [], "ratios" => [ 2 ] } }
      )).to eq(%w[anti_kropki anti_ratio])
    end

    def v3_equivalent
      {
        "formatVersion" => 3,
        "grid" => { "rows" => 9, "cols" => 9 },
        "activeConstraints" => [
          { "id" => "u1", "type" => "thermometer" },
          { "id" => "u2", "type" => "x_sums" },
          { "id" => "u3", "type" => "anti_xv" },
          { "id" => "u4", "type" => "cosmetic_line" },
          { "id" => "u5", "type" => "disjoint_sets" }
        ],
        "globals" => {
          "variants" => %w[anti_x disjoint_sets],
          "custom" => [ { "id" => "u6", "type" => "anti_sum", "value" => 12 } ]
        },
        "constraints" => { "singleCellMarks" => {}, "connectorDots" => {}, "outerClues" => {} },
        "cosmetics" => { "instances" => [ { "id" => "u7", "type" => "cosmetic_line", "data" => { "cells" => [], "presetId" => "lp" } } ] }
      }
    end

    it "matches the v3 extraction for a migrated definition" do
      expect(described_class.extract(PuzzleDefinition::Migrator.v3_to_v4(v3_equivalent)))
        .to eq(described_class.extract(v3_equivalent))
    end
  end
end
