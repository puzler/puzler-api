require "rails_helper"

RSpec.describe Scl::Encoder do
  # A PRE-v4 definition exercising one of each constraint family. Kept
  # deliberately in the old shape: the encoder normalizes every input through
  # PuzzleDefinition::Migrator at entry, so this suite doubles as proof that
  # migrate-at-entry works for the SCL path too. String keys, as stored in
  # the jsonb.
  subject(:result) { described_class.call(definition: definition, solution: solution, include_solution: true, fallback_author: "fallback") }

  let(:definition) do
    {
      "grid" => { "rows" => 9, "cols" => 9 },
      "meta" => { "name" => "Rich", "author" => "", "rules" => "Do the thing." },
      "givenDigits" => { "r0c0" => 1 },
      "globals" => {
        "variants" => %w[positive_diagonal kings_move anti_positive_diagonal],
        "custom" => [ { "type" => "anti_diff", "value" => 3 } ]
      },
      "constraints" => {
        "singleCellMarks" => { "odd_cells" => [ "r1c1" ], "even_cells" => [ "r1c2" ], "minimums" => [ "r1c3" ], "counting_circles" => [ "r6c6" ], "row_index_cells" => [ "r1c0" ] },
        "connectorDots" => {
          "r2c0|r2c1" => { "type" => "difference_dots", "value" => 3 },
          "r2c2|r2c3" => { "type" => "ratio_dots", "value" => nil },
          "r2c4|r2c5" => { "type" => "xv", "value" => "X" },
          "+r3c3" => { "type" => "quadruples", "value" => [ 1, 2, 3 ] },
          "r5c5|r6c5" => { "type" => "inequality", "value" => ">" }
        },
        "outerClues" => {
          "o:r-1c2" => { "type" => "skyscrapers", "value" => 3 },
          "o:r0c-1" => { "type" => "little_killers", "value" => 5, "direction" => "down-right" },
          "o:r6c-1" => { "type" => "rossini", "value" => nil, "rossiniDirection" => "increasing" }
        }
      },
      "cosmetics" => {
        "cellColors" => { "r0c5" => "cp1" },
        "cellColorPresets" => [ { "id" => "cp1", "color" => "#ABCDEF" } ],
        "instances" => [
          { "id" => "i1", "type" => "thermometer", "data" => { "root" => "r4c0", "edges" => [ { "from" => "r4c0", "to" => "r4c1" }, { "from" => "r4c1", "to" => "r4c2" }, { "from" => "r4c1", "to" => "r5c1" } ] } },
          { "id" => "i4", "type" => "killer_cage", "data" => { "cells" => [ "r0c7", "r0c8" ], "sum" => 10 } },
          { "id" => "i5", "type" => "arrow", "data" => { "bulbCells" => [ "r6c0" ], "arrows" => [ { "cells" => [ "r6c0", "r6c1", "r7c2" ] } ] } },
          { "id" => "i6", "type" => "clone", "data" => { "cells" => [ "r0c0" ], "copies" => [ { "dRow" => 1, "dCol" => 1 } ] } },
          { "id" => "i12", "type" => "renban", "data" => { "cells" => [ "r8c5", "r8c6" ] } },
          { "id" => "i17", "type" => "lockout_lines", "data" => { "cells" => [ "r3c7", "r3c8" ] } }
        ]
      }
    }
  end
  let(:solution) { { "r0c0" => 1, "r0c1" => 2 } }
  let(:data) { result.data }

  def meta_cages(data)
    (data["cages"] || []).select { |c| c["cells"].nil? }.map { |c| c["value"] }
  end

  def overlay(data, **fields)
    (data["overlays"] || []).find { |o| fields.all? { |k, v| o[k.to_s] == v } }
  end

  def underlay_at(data, center)
    (data["underlays"] || []).find { |u| u["center"] == center }
  end

  it "emits meta-cages for title, author, rules, and the row-major solution", :aggregate_failures do
    expect(meta_cages(data)).to include("title: Rich", "author: fallback", "rules: Do the thing.")
    expect(meta_cages(data)).to include("solution: 12#{'?' * 79}")
  end

  it "builds the cells grid with 1-indexed doc keys mapped to 0-indexed cells", :aggregate_failures do
    expect(data["cellSize"]).to eq(64)
    expect(data["cells"][0][0]).to include("value" => 1, "given" => true)
    expect(data["cells"][0][5]["c"]).to eq("#ABCDEF")
    expect([ data["cells"].length, data["cells"][0].length ]).to eq([ 9, 9 ])
  end

  it "maps thermometers to one line per root-to-leaf path, repeating branch prefixes" do
    thermo_lines = data["lines"].select { |l| l["color"] == "#aaaaaa" && l["thickness"] == 12 }
    expect(thermo_lines.map { |l| l["wayPoints"] }).to contain_exactly(
      [ [ 4.5, 0.5 ], [ 4.5, 1.5 ], [ 4.5, 2.5 ] ],
      [ [ 4.5, 0.5 ], [ 4.5, 1.5 ], [ 5.5, 1.5 ] ]
    )
  end

  it "draws a filled thermometer bulb" do
    expect(underlay_at(data, [ 4.5, 0.5 ])).to include("rounded" => true, "backgroundColor" => "#aaaaaa")
  end

  it "maps killer cages to unique SCL cages with the sum on the top-left cell", :aggregate_failures do
    cage = data["cages"].find { |c| c["value"] == "10" }
    expect(cage).to include("unique" => true)
    expect(cage["cells"]).to eq([ [ 0, 7 ], [ 0, 8 ] ])
  end

  it "maps arrows to native SCL arrows started at the bulb rim", :aggregate_failures do
    arrow = data["arrows"].find { |a| a["thickness"] == 2.5 }
    expect(arrow["wayPoints"][0]).not_to eq([ 6.5, 0.5 ]) # inset toward the next point
    expect(arrow["wayPoints"][1]).to eq([ 6.5, 1.5 ])
  end

  it "draws the arrow bulb as an outlined overlay" do
    expect(overlay(data, center: [ 6.5, 0.5 ], rounded: true)).to include("borderColor" => "#aaaaaa")
  end

  it "maps constraint lines in Puzler's default colors", :aggregate_failures do
    renban = data["lines"].find { |l| l["color"] == "#f067f0" }
    expect(renban).to include("thickness" => 8, "wayPoints" => [ [ 8.5, 5.5 ], [ 8.5, 6.5 ] ])
  end

  it "gives lockout lines their end diamonds", :aggregate_failures do
    expect(data["lines"].find { |l| l["color"] == "#bbbbbb" }).to be_present
    diamonds = data["overlays"].select { |o| o["angle"] == 45 && o["borderColor"] == "#4a90d9" }
    expect(diamonds.length).to eq(2)
  end

  it "maps kropki dots to edge-midpoint overlays", :aggregate_failures do
    expect(overlay(data, center: [ 2.5, 1 ])).to include("backgroundColor" => "#FFFFFF", "text" => "3")
    expect(overlay(data, center: [ 2.5, 3 ])).to include("backgroundColor" => "#000000", "text" => "")
  end

  it "maps XV and inequality glyphs to edge midpoints", :aggregate_failures do
    expect(overlay(data, text: "X")["center"]).to eq([ 2.5, 5 ])
    expect(overlay(data, text: "∨", fontSize: 19.2)["center"]).to eq([ 6, 5.5 ])
  end

  it "places quadruples on the 2x2's shared gridline intersection" do
    expect(overlay(data, text: "123")["center"]).to eq([ 3, 3 ])
  end

  it "maps outer clues to text overlays outside the grid", :aggregate_failures do
    expect(overlay(data, text: "3", fontSize: 41.6)["center"]).to eq([ -0.5, 2.5 ])
    expect(overlay(data, text: "5")["center"]).to eq([ 0.5, -0.5 ])
    expect(overlay(data, text: "→")["center"]).to eq([ 6.5, -0.5 ])
  end

  it "draws the little-killer direction arrow" do
    expect(data["arrows"].find { |a| a["thickness"] == 1.75 }).to be_present
  end

  it "maps odd and even marks", :aggregate_failures do
    expect(underlay_at(data, [ 1.5, 1.5 ])).to include("rounded" => true, "backgroundColor" => "#bbbbbb", "width" => 0.75)
    expect(underlay_at(data, [ 1.5, 2.5 ])).to include("backgroundColor" => "#bbbbbb", "width" => 0.7)
    expect(underlay_at(data, [ 1.5, 2.5 ])["rounded"]).to be_nil
  end

  it "maps minimum cells to a tint plus four chevrons", :aggregate_failures do
    expect(underlay_at(data, [ 1.5, 3.5 ])).to include("backgroundColor" => "#f0f0f0")
    chevrons = data["overlays"].select { |o| %w[∨ ∧ < >].include?(o["text"]) && o["fontSize"] == 14 }
    expect(chevrons.length).to eq(4)
  end

  it "maps counting circles and indexer tints", :aggregate_failures do
    expect(overlay(data, center: [ 6.5, 6.5 ])).to include("borderColor" => "#666666", "rounded" => true)
    expect(data["cells"][1][0]["c"]).to eq("#ffc8c8b3") # row indexer tint at 0.7 opacity
  end

  it "maps clones to grey underlays on originals and copies" do
    fills = data["underlays"].select { |u| u["backgroundColor"] == "#cccccc" }
    expect(fills.map { |u| u["center"] }).to contain_exactly([ 0.5, 0.5 ], [ 1.5, 1.5 ])
  end

  it "draws diagonals as corner-to-corner lines", :aggregate_failures do
    expect(data["lines"].find { |l| l["wayPoints"] == [ [ 9, 0 ], [ 0, 9 ] ] && l["color"] == "#93c5fdd9" }).to be_present
    expect(data["lines"].find { |l| l["wayPoints"] == [ [ 9, 0 ], [ 0, 9 ] ] && l["color"] == "#f87171d9" }).to be_present
  end

  it "reports globals SudokuPad cannot conflict-check in one aggregated warning" do
    expect(result.warnings.join).to include("anti-king").and include("anti diff (3)").and include("clones")
  end

  describe "relaxed grid support (v4 documents)" do
    def v4(grid_extra = {}, extra = {})
      {
        "formatVersion" => 4,
        "grid" => { "rows" => 9, "cols" => 9 }.merge(grid_extra),
        "globals" => { "sudokuRules" => {} }
      }.merge(extra)
    end

    def void_definition
      {
        "formatVersion" => 4,
        "grid" => { "rows" => 2, "cols" => 2, "regions" => { "1" => [ "r1c1", "r1c2", "r2c1" ] } },
        "globals" => { "sudokuRules" => {} }
      }
    end

    def custom_houses_definition
      {
        "formatVersion" => 4,
        "grid" => { "rows" => 9, "cols" => 9 },
        "globals" => { "sudokuRules" => { "enabled" => true, "custom" => true } },
        "constraints" => { "houses" => [ { "cells" => %w[r1c1 r2c2 r3c3] } ] }
      }
    end

    it "exports non-square grids", :aggregate_failures do
      data = described_class.call(definition: v4("rows" => 4, "cols" => 6)).data
      expect(data["cells"].length).to eq(4)
      expect(data["cells"][0].length).to eq(6)
    end

    it "emits overlapping regions as-is" do
      data = described_class.call(definition: v4("regions" => { "1" => [ "r1c1", "r1c2" ], "2" => [ "r1c2", "r1c3" ] })).data
      expect(data["regions"]).to eq([ [ [ 0, 0 ], [ 0, 1 ] ], [ [ 0, 1 ], [ 0, 2 ] ] ])
    end

    # The corner void extends past the grid edge (down/right) and insets from
    # its live neighbors (up/left) so SudokuPad's 3px region outline survives.
    it "covers void cells with edge-aware white overlays", :aggregate_failures do
      result = described_class.call(definition: void_definition)
      cover = result.data["overlays"].find { |o| o["backgroundColor"] == "#FFFFFF" }
      expect(cover).to include("width" => 1.0266, "height" => 1.0266)
      expect(cover["center"]).to eq([ 1.5367, 1.5367 ])
      expect(result.warnings.join).to include("Void cells")
    end

    it "skips void cells in the solution string" do
      result = described_class.call(definition: void_definition, solution: { "r0c0" => 1, "r0c1" => 2, "r1c0" => 3 })
      expect(meta_cages(result.data)).to include("solution: 123?")
    end

    it "hides custom houses as invisible unique cages", :aggregate_failures do
      house = described_class.call(definition: custom_houses_definition).data["cages"].find { |c| c["cells"] }
      expect(house).to include("unique" => true, "outlineC" => "#00000000")
      expect(house["cells"]).to eq([ [ 0, 0 ], [ 1, 1 ], [ 2, 2 ] ])
    end

    it "suppresses row/col checking for custom-house puzzles via metadata.norowcol", :aggregate_failures do
      result = described_class.call(definition: custom_houses_definition)
      expect(result.data["metadata"]).to eq("norowcol" => true)
      expect(result.url_params).to eq({}) # houses + regions still conflict-check
    end

    it "turns the whole conflict checker off when sudoku rules are absent", :aggregate_failures do
      definition = { "formatVersion" => 4, "grid" => { "rows" => 9, "cols" => 9 } }
      result = described_class.call(definition: definition)
      expect(result.data["metadata"]).to eq("norowcol" => true)
      expect(result.url_params).to eq("setting-conflictchecker" => "false")
      expect(result.warnings.join).to include("conflict highlighting")
    end

    it "keeps standard-rules puzzles free of settings params and metadata flags", :aggregate_failures do
      result = described_class.call(definition: v4)
      expect(result.url_params).to eq({})
      expect(result.data["metadata"]).to be_nil
    end

    it "downgrades a mismatched digit range to a warning" do
      result = described_class.call(definition: v4("digits" => 6))
      expect(result.warnings.join).to include("digit range")
    end

    it "still raises on malformed grid dimensions" do
      expect { described_class.call(definition: { "grid" => { "rows" => 0, "cols" => 9 } }) }
        .to raise_error(Scl::UnsupportedGrid)
    end
  end

  describe "fog" do
    let(:fog_definition) do
      {
        "formatVersion" => 4,
        "grid" => { "rows" => 9, "cols" => 9 },
        "globals" => { "sudokuRules" => {}, "fog" => { "enabled" => true } },
        "constraints" => { "fogLights" => [ "r1c1", { "cell" => "r5c5" } ] }
      }
    end

    it "emits foglight cells and forces the solution in", :aggregate_failures do
      result = described_class.call(definition: fog_definition, solution: { "r0c0" => 4 }, include_solution: false)
      expect(result.data["foglight"]).to eq([ [ 0, 0 ], [ 4, 4 ] ])
      expect(meta_cages(result.data).join).to include("solution: 4")
    end

    it "warns when fog has no solution to embed" do
      result = described_class.call(definition: fog_definition, solution: nil)
      expect(result.warnings.join).to include("Fog needs an embedded solution")
    end
  end

  describe "solution edge cases" do
    it "skips the solution and warns when digits exceed 9", :aggregate_failures do
      definition = { "formatVersion" => 4, "grid" => { "rows" => 9, "cols" => 9 }, "globals" => { "sudokuRules" => {} } }
      result = described_class.call(definition: definition, solution: { "r0c0" => 12 })
      expect(meta_cages(result.data).join).not_to include("solution:")
      expect(result.warnings.join).to include("single-digit")
    end
  end

  describe "cosmetics" do
    let(:cosmetic_definition) do
      {
        "formatVersion" => 4,
        "grid" => { "rows" => 9, "cols" => 9 },
        "globals" => { "sudokuRules" => {} },
        "cosmetics" => {
          "lines" => [ { "cells" => %w[r1c1 r2c2], "preset" => "l1" } ],
          "linePresets" => [ { "id" => "l1", "style" => { "color" => "#FF8800", "strokeWidth" => 6, "opacity" => 0.5 } } ],
          "borders" => [ { "edges" => [ %w[r1c1 r1c2], %w[r3c3 r4c3] ], "preset" => "b1" } ],
          "borderPresets" => [ { "id" => "b1", "style" => { "color" => "#AA0000", "strokeWidth" => 4 } } ],
          "shapes" => [ { "pos" => { "x" => 2.5, "y" => 3.5 }, "preset" => "s1", "content" => "Q" } ],
          "shapePresets" => [ { "id" => "s1", "style" => { "shapeType" => "diamond", "fillColor" => "#FFEE00", "strokeColor" => "#333333", "width" => 0.4, "height" => 0.4, "textColor" => "#111111", "textSize" => 18 } } ],
          "texts" => [ { "pos" => { "x" => 5.5, "y" => 0.5 }, "preset" => "t1", "content" => "HI", "rotation" => 90 } ],
          "textPresets" => [ { "id" => "t1", "style" => { "color" => "#0066CC", "fontSize" => 24 } } ],
          "cages" => [ { "cells" => %w[r5c5 r5c6], "sum" => 9, "preset" => "c1" } ],
          "cagePresets" => [ { "id" => "c1", "style" => { "cageColor" => "#009900", "cageOpacity" => 0.5, "textColor" => "#009900" } } ]
        }
      }
    end
    let(:cosmetic_data) { described_class.call(definition: cosmetic_definition).data }

    it "maps cosmetic lines with blended opacity", :aggregate_failures do
      line = cosmetic_data["lines"].find { |l| l["thickness"] == 6 }
      expect(line).to include("color" => "#FF880080")
      expect(line["wayPoints"]).to eq([ [ 0.5, 0.5 ], [ 1.5, 1.5 ] ])
    end

    it "maps cosmetic borders to gridline edge segments" do
      borders = cosmetic_data["lines"].select { |l| l["thickness"] == 4 }
      expect(borders.map { |l| l["wayPoints"] }).to contain_exactly(
        [ [ 0, 1 ], [ 1, 1 ] ], # vertical edge between r1c1|r1c2
        [ [ 3, 2 ], [ 3, 3 ] ]  # horizontal edge between r3c3|r4c3
      )
    end

    it "maps shapes with diamond rotation, free positions, and text", :aggregate_failures do
      shape = overlay(cosmetic_data, text: "Q")
      expect(shape).to include("angle" => 45, "backgroundColor" => "#FFEE00", "fontSize" => 18)
      expect(shape["center"]).to eq([ 2.5, 1.5 ]) # pos x/y are 1-indexed cell units
    end

    it "maps texts with rotation" do
      expect(overlay(cosmetic_data, text: "HI")).to include("fontSize" => 24, "color" => "#0066CC", "angle" => 90)
    end

    it "maps cosmetic cages without uniqueness", :aggregate_failures do
      cage = cosmetic_data["cages"].find { |c| c["value"] == "9" }
      expect(cage["unique"]).to be_nil
      expect(cage).to include("outlineC" => "#00990080", "fontC" => "#009900")
    end
  end
end
