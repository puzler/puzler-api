require "rails_helper"

RSpec.describe PuzzleDefinition::Migrator do
  describe ".v3_to_v4" do
    # Mirrors the frontend migrator fixture (app/src/utils/puzzleExport.test.ts,
    # 'migratePuzzleDocument (v3 → v4)') — a realistic v3 export: storage
    # buckets, location-keyed maps, UUIDs, 0-indexed cell keys.
    let(:v3_doc) do
      {
        "formatVersion" => 3,
        "grid" => { "rows" => 9, "cols" => 9, "customCellRegions" => { "r0c0" => nil } },
        "meta" => { "name" => "Old Puzzle", "rules" => "Rules." },
        "givenDigits" => { "r0c0" => 5 },
        "activeConstraints" => [
          { "id" => "u1", "type" => "thermometer", "label" => "Thermometers", "category" => "line" },
          { "id" => "u2", "type" => "x_sums", "label" => "X-Sums", "category" => "outer" },
          { "id" => "u3", "type" => "anti_xv", "label" => "Anti-XV", "category" => "global" },
          { "id" => "u4", "type" => "cosmetic_line", "label" => "Line", "category" => "cosmetic" }
        ],
        "globals" => { "variants" => [ "anti_x" ], "custom" => [ { "id" => "u5", "type" => "anti_sum", "value" => 12 } ] },
        "constraints" => {
          "singleCellMarks" => { "odd_cells" => [ "r1c1" ] },
          "connectorDots" => {
            "r4c4|r4c5" => { "type" => "difference_dots", "value" => 2 },
            "+r3c3" => { "type" => "quadruples", "value" => [ 1, 2 ] }
          },
          "outerClues" => {
            "o:r-1c3" => { "type" => "x_sums", "value" => 20 },
            "o:r9c2" => { "type" => "rossini", "value" => nil, "rossiniDirection" => "increasing" }
          }
        },
        "cosmetics" => {
          "cellColors" => { "r0c5" => "cp1" },
          "cellColorPresets" => [ { "id" => "cp1", "label" => "Yellow", "color" => "#fff9c4" } ],
          "instances" => [
            { "id" => "u6", "type" => "thermometer", "data" => { "root" => "r0c0", "edges" => [ { "from" => "r0c0", "to" => "r0c1" } ] } },
            { "id" => "u7", "type" => "cosmetic_line", "data" => { "cells" => [ "r6c0", "r6c1" ], "presetId" => "lp1" } }
          ],
          "linePresets" => [ { "id" => "lp1", "label" => "Grey", "style" => { "color" => "#777777", "strokeWidth" => 8, "opacity" => 1 } } ]
        }
      }
    end

    let(:migrated) { described_class.v3_to_v4(v3_doc) }

    let(:expected_constraints) do
      {
        "thermometers" => [ { "bulb" => "r1c1", "lines" => [ %w[r1c1 r1c2] ] } ],
        "differenceDots" => [ { "cells" => %w[r5c5 r5c6], "value" => 2 } ],
        "quadruples" => [ { "cells" => %w[r3c3 r3c4 r4c3 r4c4], "values" => [ 1, 2 ] } ],
        "oddCells" => [ "r2c2" ],
        "xSums" => [ { "cell" => "r0c4", "value" => 20 } ],
        "rossini" => [ { "cell" => "r10c3", "direction" => "increasing" } ]
      }
    end

    let(:expected_cosmetics) do
      {
        "lines" => [ { "cells" => %w[r7c1 r7c2], "preset" => "line-1" } ],
        "linePresets" => [ { "id" => "line-1", "label" => "Grey", "style" => { "color" => "#777777", "strokeWidth" => 8, "opacity" => 1 } } ],
        "cellColors" => { "r1c6" => "color-1" },
        "cellColorPresets" => [ { "id" => "color-1", "label" => "Yellow", "color" => "#fff9c4" } ]
      }
    end

    def migrate(doc)
      described_class.v3_to_v4(doc)
    end

    it "converts version, meta, givens, and grouped globals", :aggregate_failures do
      expect(migrated["formatVersion"]).to eq(4)
      expect(migrated["meta"]).to eq("name" => "Old Puzzle", "rules" => "Rules.")
      expect(migrated["givenDigits"]).to eq("r1c1" => 5)
      expect(migrated["globals"]).to eq("antiXv" => { "x" => true, "sums" => [ 12 ] })
    end

    it "converts the constraint buckets to one 1-indexed array per type" do
      expect(migrated["constraints"]).to eq(expected_constraints)
    end

    it "converts cosmetics to kind arrays with canonical preset slugs" do
      expect(migrated["cosmetics"]).to eq(expected_cosmetics)
    end

    it "drops instance and custom-global UUIDs" do
      expect(JSON.generate(migrated)).not_to include('"id":"u')
    end

    it "emits document keys in registry-canonical order", :aggregate_failures do
      expect(migrated.keys).to eq(%w[formatVersion grid meta givenDigits globals constraints cosmetics])
      expect(migrated["constraints"].keys).to eq(%w[thermometers differenceDots quadruples oddCells xSums rossini])
      expect(migrated["cosmetics"].keys).to eq(%w[lines linePresets cellColors cellColorPresets])
    end

    it "expands a sparse region override map into a complete region-first layout", :aggregate_failures do
      regions = migrated.dig("grid", "regions")
      expect(regions.keys).to eq(%w[1 2 3 4 5 6 7 8 9])
      # r0c0 (doc r1c1) was overridden to regionless: box 1 loses it, the rest
      # of the standard layout is expanded explicitly.
      expect(regions["1"]).to eq(%w[r1c2 r1c3 r2c1 r2c2 r2c3 r3c1 r3c2 r3c3])
      expect(regions["5"]).to eq(%w[r4c4 r4c5 r4c6 r5c4 r5c5 r5c6 r6c4 r6c5 r6c6])
      expect(regions.values.flatten).not_to include("r1c1")
    end

    it "omits regions when the overrides match the standard box layout" do
      doc = migrate("formatVersion" => 3, "grid" => { "rows" => 9, "cols" => 9, "customCellRegions" => { "r0c0" => "1" } })
      expect(doc["grid"]).to eq("rows" => 9, "cols" => 9)
    end

    it "computes non-9x9 standard boxes when expanding overrides" do
      doc = migrate("formatVersion" => 3, "grid" => { "rows" => 4, "cols" => 4, "customCellRegions" => { "r0c0" => "2" } })
      expect(doc.dig("grid", "regions")).to eq("1" => %w[r1c2 r2c1 r2c2], "2" => %w[r1c1 r1c3 r1c4 r2c3 r2c4], "3" => %w[r3c1 r3c2 r4c1 r4c2], "4" => %w[r3c3 r3c4 r4c3 r4c4])
    end

    it "is idempotent: v4 input is returned untouched", :aggregate_failures do
      expect(described_class.v3_to_v4(migrated)).to be(migrated)
      versioned = { "formatVersion" => 4, "grid" => { "rows" => 9, "cols" => 9 } }
      expect(described_class.v3_to_v4(versioned)).to be(versioned)
    end

    it "returns blank input untouched", :aggregate_failures do
      expect(described_class.v3_to_v4(nil)).to be_nil
      expect(described_class.v3_to_v4({})).to eq({})
    end

    it "keeps active-but-empty chips as empty entries", :aggregate_failures do
      doc = migrate("formatVersion" => 3, "grid" => { "rows" => 9, "cols" => 9 }, "activeConstraints" => [ { "id" => "a", "type" => "renban" }, { "id" => "b", "type" => "diagonals" } ])
      expect(doc["constraints"]).to eq("renbanLines" => [])
      expect(doc["globals"]).to eq("diagonals" => {})
    end

    it "shifts sorted single-cell marks without re-sorting the document keys" do
      doc = migrate("formatVersion" => 3, "grid" => { "rows" => 12, "cols" => 12 }, "constraints" => { "singleCellMarks" => { "odd_cells" => %w[r9c0 r10c0] } })
      # v3 cells sort as internal keys ("r10c0" < "r9c0"), then shift +1.
      expect(doc["constraints"]).to eq("oddCells" => %w[r11c1 r10c1])
    end

    it "shifts solution keys by +1" do
      doc = migrate("formatVersion" => 3, "grid" => { "rows" => 9, "cols" => 9 }, "solution" => { "r0c0" => 1, "r8c8" => 9 })
      expect(doc["solution"]).to eq("r1c1" => 1, "r9c9" => 9)
    end

    def v2_era_blob
      {
        "version" => 2,
        "grid" => { "rows" => 9, "cols" => 9 },
        "activeConstraints" => [ { "id" => "x", "type" => "text", "label" => "Text", "category" => "cosmetic" } ],
        "cosmetics" => {
          "instances" => [ { "id" => "t", "type" => "text", "data" => { "cell" => "r4c4", "anchor" => "top-left", "presetId" => "tp1" } } ],
          "textPresets" => [ { "id" => "tp1", "label" => "Label", "content" => "A", "style" => { "color" => "#333333", "fontSize" => 20, "bold" => false } } ],
          "shapePresets" => [ { "id" => "sp1", "label" => "Circle", "style" => { "shapeType" => "circle", "fillColor" => "none", "strokeColor" => "#333", "strokeWidth" => 2, "size" => 0.4, "textColor" => "#333", "textSize" => 20 } } ]
        }
      }
    end

    it "migrates v2-era cell-anchored text to a free position with copied preset content", :aggregate_failures do
      doc = migrate(v2_era_blob)
      # Document coordinates: cell r5c5's centre is x 5.5, the top-left anchor
      # shifts -0.5 each way.
      expect(doc.dig("cosmetics", "texts")).to eq([ { "pos" => { "x" => 5, "y" => 5 }, "content" => "A", "preset" => "text-1" } ])
      expect(doc.dig("cosmetics", "textPresets")).to eq([ { "id" => "text-1", "label" => "Label", "style" => { "color" => "#333333", "fontSize" => 20, "bold" => false } } ])
    end

    it "drops presets for inactive cosmetic kinds (matching the old preset gating)" do
      expect(migrate(v2_era_blob)["cosmetics"]).not_to have_key("shapePresets")
    end

    def legacy_shape_doc
      {
        "formatVersion" => 3,
        "grid" => { "rows" => 9, "cols" => 9 },
        "activeConstraints" => [ { "id" => "s", "type" => "shape" } ],
        "cosmetics" => {
          "instances" => [ { "id" => "i", "type" => "shape", "data" => { "pos" => { "x" => 4.5, "y" => 4.5 }, "content" => "", "rotation" => 30, "presetId" => "sp1" } } ],
          "shapePresets" => [ { "id" => "sp1", "label" => "Diamond", "style" => { "shapeType" => "diamond", "fillColor" => "none", "strokeColor" => "#333333", "size" => 0.4, "textColor" => "#000000" } } ]
        }
      }
    end

    it "migrates legacy shape preset size to explicit width/height without sizeLinked", :aggregate_failures do
      doc = migrate(legacy_shape_doc)
      expect(doc.dig("cosmetics", "shapes")).to eq([ { "pos" => { "x" => 5.5, "y" => 5.5 }, "rotation" => 30, "preset" => "shape-1" } ])
      expect(doc.dig("cosmetics", "shapePresets")).to eq([ { "id" => "shape-1", "label" => "Diamond", "style" => { "shapeType" => "diamond", "fillColor" => "none", "strokeColor" => "#333333", "textColor" => "#000000", "width" => 0.4, "height" => 0.4 } } ])
    end
  end
end
