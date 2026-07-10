require "rails_helper"

RSpec.describe Fpuzzles::Encoder do
  # A PRE-v4 definition exercising one of each constraint family (mirrors the
  # frontend converter's coverage). Kept deliberately in the old shape: the
  # encoder normalizes every input through PuzzleDefinition::Migrator at entry,
  # so this whole suite doubles as proof that migrate-at-entry preserves the
  # legacy output. String keys, as stored in the jsonb.
  subject(:result) { described_class.call(definition: definition, solution: solution, include_solution: true, fallback_author: "fallback") }

  let(:definition) do
    {
      "grid" => { "rows" => 9, "cols" => 9 },
      "meta" => { "name" => "Rich", "author" => "" },
      "givenDigits" => { "r0c0" => 1 },
      "globals" => {
        "variants" => %w[positive_diagonal kings_move knights_move nonconsecutive disjoint_sets anti_black_kropki anti_x anti_positive_diagonal],
        "custom" => [ { "type" => "anti_diff", "value" => 1 }, { "type" => "anti_diff", "value" => 3 } ]
      },
      "constraints" => {
        "singleCellMarks" => { "odd_cells" => [ "r1c1" ], "minimums" => [ "r1c3" ], "row_index_cells" => [ "r0c6", "r1c0" ], "col_index_cells" => [ "r0c6" ], "counting_circles" => [ "r6c6" ] },
        "connectorDots" => {
          "r2c0|r2c1" => { "type" => "difference_dots", "value" => 3 }, "r2c2|r2c3" => { "type" => "ratio_dots", "value" => nil },
          "r2c4|r2c5" => { "type" => "xv", "value" => "X" }, "+r3c3" => { "type" => "quadruples", "value" => [ 1, 2, 3 ] },
          "r2c6|r2c7" => { "type" => "inequality", "value" => "<" }, "r5c5|r6c5" => { "type" => "inequality", "value" => ">" }
        },
        "outerClues" => {
          "o:r-1c2" => { "type" => "skyscrapers", "value" => 3 },
          "o:r0c-1" => { "type" => "little_killers", "value" => 5, "direction" => "down-right" },
          "o:r4c9" => { "type" => "numbered_rooms", "value" => 7 },
          "o:r-1c6" => { "type" => "battlefield", "value" => 12 },
          "o:r9c3" => { "type" => "next_to_nine", "value" => 34 },
          "o:r6c-1" => { "type" => "rossini", "value" => nil, "rossiniDirection" => "increasing" }
        }
      },
      "cosmetics" => {
        "cellColors" => { "r0c5" => "cp1", "r0c6" => "cp1" },
        "cellColorPresets" => [ { "id" => "cp1", "color" => "#ABCDEF" } ],
        "shapePresets" => [ { "id" => "sp1", "style" => { "shapeType" => "diamond", "fillColor" => "none", "strokeColor" => "#333333", "size" => 0.5, "textColor" => "#000000" } } ],
        "instances" => [
          { "id" => "i1", "type" => "thermometer", "data" => { "root" => "r4c0", "edges" => [ { "from" => "r4c0", "to" => "r4c1" }, { "from" => "r4c1", "to" => "r4c2" }, { "from" => "r4c1", "to" => "r5c1" } ] } },
          { "id" => "i4", "type" => "killer_cage", "data" => { "cells" => [ "r0c7", "r0c8" ], "sum" => 10 } },
          { "id" => "i6", "type" => "clone", "data" => { "cells" => [ "r0c0" ], "copies" => [ { "dRow" => 1, "dCol" => 1 } ] } },
          { "id" => "i10", "type" => "shape", "data" => { "pos" => { "x" => 4.5, "y" => 4.5 }, "content" => "X", "rotation" => 30, "presetId" => "sp1" } },
          { "id" => "i12", "type" => "renban", "data" => { "cells" => [ "r8c5", "r8c6" ] } },
          { "id" => "i13", "type" => "entropic_lines", "data" => { "cells" => [ "r7c0", "r7c1" ] } },
          { "id" => "i14", "type" => "modular_lines", "data" => { "cells" => [ "r6c0", "r6c1" ] } },
          { "id" => "i15", "type" => "nabner_lines", "data" => { "cells" => [ "r5c7", "r5c8" ] } },
          { "id" => "i16", "type" => "zipper_lines", "data" => { "cells" => [ "r4c7", "r4c8" ] } },
          { "id" => "i17", "type" => "lockout_lines", "data" => { "cells" => [ "r3c7", "r3c8" ] } }
        ]
      }
    }
  end
  let(:solution) { { "r0c0" => 1, "r0c1" => 2 } }
  let(:data) { result.data }
  let(:stretched_definition) do
    {
      "grid" => { "rows" => 9, "cols" => 9 },
      "cosmetics" => {
        "shapePresets" => [ { "id" => "sp2", "style" => { "shapeType" => "circle", "fillColor" => "none", "strokeColor" => "#333333", "width" => 1.5, "height" => 0.6, "textColor" => "#000000" } } ],
        "instances" => [ { "id" => "i20", "type" => "shape", "data" => { "pos" => { "x" => 4.5, "y" => 4.5 }, "presetId" => "sp2" } } ]
      }
    }
  end



  it "maps meta, 1-indexed givens, and the row-major solution", :aggregate_failures do
    expect(data).to include("size" => 9, "title" => "Rich", "author" => "fallback")
    expect(data["grid"][0][0]).to include("value" => 1, "given" => true)
    expect(data["solution"][0, 2]).to eq(%w[1 2])
  end

  it "raises on a non-square grid" do
    expect { described_class.call(definition: { "grid" => { "rows" => 9, "cols" => 6 } }) }
      .to raise_error(Fpuzzles::UnsupportedGrid)
  end

  it "raises when sudoku rules are soft-disabled (SudokuPad always enforces them)" do
    definition = { "formatVersion" => 4, "grid" => { "rows" => 9, "cols" => 9 }, "globals" => { "sudokuRules" => { "enabled" => false } } }
    expect { described_class.call(definition: definition) }
      .to raise_error(Fpuzzles::UnsupportedGrid, /sudoku rules/)
  end

  it "raises when the sudokuRules key is absent from a v4 document (rules-off puzzle)" do
    definition = { "formatVersion" => 4, "grid" => { "rows" => 9, "cols" => 9 } }
    expect { described_class.call(definition: definition) }
      .to raise_error(Fpuzzles::UnsupportedGrid, /sudoku rules/)
  end

  it "accepts a bare sudokuRules presence marker (chip on, rules on)" do
    definition = { "formatVersion" => 4, "grid" => { "rows" => 9, "cols" => 9 }, "globals" => { "sudokuRules" => {} } }
    expect(described_class.call(definition: definition).data).to include("size" => 9)
  end

  it "accepts pre-v4 documents (the migrator stamps the rules group on)" do
    expect(described_class.call(definition: { "grid" => { "rows" => 9, "cols" => 9 } }).data).to include("size" => 9)
  end

  describe "cosmetic borders" do
    # Plain helpers, not lets: the outer group already sits at the memoized cap.
    def border_rects
      definition = {
        "formatVersion" => 4,
        "globals" => { "sudokuRules" => {} },
        "grid" => { "rows" => 9, "cols" => 9 },
        "cosmetics" => {
          "borders" => [ { "edges" => [ [ "r1c1", "r1c2" ], [ "r2c2", "r3c2" ] ], "preset" => "border-1" } ],
          "borderPresets" => [ { "id" => "border-1", "label" => "Border", "style" => { "color" => "#232B3D", "strokeWidth" => 2.5, "opacity" => 1 } } ]
        }
      }
      described_class.call(definition: definition).data["rectangle"]
    end

    it "spans a vertical edge with a thin full-height rectangle", :aggregate_failures do
      # Horizontal neighbours (r1c1|r1c2) share a vertical edge.
      rects = border_rects
      expect(rects.length).to eq(2)
      expect(rects[0]).to include("cells" => %w[R1C1 R1C2], "width" => 2.5 / 64.0, "height" => 1, "baseC" => "#232B3D")
    end

    it "spans a horizontal edge with a thin full-width rectangle" do
      # Vertical neighbours (r2c2|r3c2) share a horizontal edge.
      expect(border_rects[1]).to include("cells" => %w[R2C2 R3C2], "width" => 1, "height" => 2.5 / 64.0)
    end
  end

  it "maps global variants and negative constraints", :aggregate_failures do
    expect(data).to include("diagonal+" => true, "antiking" => true, "antiknight" => true, "nonconsecutive" => true, "disjointgroups" => true)
    expect(data["negative"]).to contain_exactly("ratio", "xv", "difference")
  end

  it "draws an anti-diagonal as a cosmetic line" do
    expect(data["line"].first).to include("outlineC" => "#f06292", "width" => 0.05, "isNewConstraint" => true)
  end

  it "tints index cells but lets a cosmetic colour win", :aggregate_failures do
    expect(data["grid"][1][0]).to eq("c" => "#FFD9D9") # plain row-index cell
    expect(data["grid"][0][6]).to eq("c" => "#ABCDEF") # both-index cell, overridden by cellColor cp1
  end

  it "maps single-cell marks and the indexer field", :aggregate_failures do
    expect(data["odd"]).to eq([ { "cell" => "R2C2" } ])
    expect(data["minimum"]).to eq([ { "cell" => "R2C4" } ])
    expect(data["rowindexer"]).to eq([ { "cells" => %w[R1C7 R2C1] } ])
  end

  it "maps connector dots and quadruples", :aggregate_failures do
    expect(data["difference"]).to eq([ { "cells" => %w[R3C1 R3C2], "value" => "3" } ])
    expect(data["ratio"]).to eq([ { "cells" => %w[R3C3 R3C4], "value" => "" } ])
    expect(data["xv"]).to eq([ { "cells" => %w[R3C5 R3C6], "value" => "X" } ])
    expect(data["quadruple"].first).to include("values" => [ 1, 2, 3 ])
  end

  it "maps outer clues with a skyscraper text fallback", :aggregate_failures do
    expect(data["skyscraper"]).to eq([ { "cell" => "R0C3", "value" => "3" } ])
    expect(data["littlekillersum"].first).to include("direction" => "DR", "value" => "5")
    expect(data["text"]).to include(include("value" => "3", "fontC" => "#000000"))
  end

  it "flattens a branching thermometer into root-to-leaf lines" do
    expect(data["thermometer"].first["lines"]).to contain_exactly(%w[R5C1 R5C2 R5C3], %w[R5C1 R5C2 R6C2])
  end

  it "maps killer cage and clone", :aggregate_failures do
    expect(data["killercage"]).to eq([ { "cells" => %w[R1C8 R1C9], "value" => "10" } ])
    expect(data["clone"].first).to include("cells" => [ "R1C1" ], "cloneCells" => [ "R2C2" ])
  end

  it "maps a renban line plus its cosmetic fallback", :aggregate_failures do
    expect(data["renban"]).to eq([ { "lines" => [ %w[R9C6 R9C7] ] } ])
    expect(data["line"]).to include(include("outlineC" => "#F067F0", "width" => 0.4))
  end

  it "exports entropic, modular, nabner and zipper lines as cosmetic-only lines", :aggregate_failures do
    expect(data["line"]).to include(include("lines" => [ %w[R8C1 R8C2] ], "outlineC" => "#FA9678", "width" => 0.3))
    expect(data["line"]).to include(include("lines" => [ %w[R7C1 R7C2] ], "outlineC" => "#00B5AD", "width" => 0.3))
    expect(data["line"]).to include(include("lines" => [ %w[R6C8 R6C9] ], "outlineC" => "#F0C300", "width" => 0.3))
    expect(data["line"]).to include(include("lines" => [ %w[R5C8 R5C9] ], "outlineC" => "#AC8AFF", "width" => 0.3))
  end

  it "exports numbered rooms, battlefield and next-to-nine clues as cosmetic text only", :aggregate_failures do
    expect(data["text"]).to include(include("cells" => [ "R5C10" ], "value" => "7", "size" => 0.7))
    expect(data["text"]).to include(include("cells" => [ "R0C7" ], "value" => "12", "size" => 0.7))
    expect(data["text"]).to include(include("cells" => [ "R10C4" ], "value" => "34", "size" => 0.7))
  end

  it "exports counting circles as cosmetic outline rings" do
    expect(data["circle"]).to include(include("cells" => [ "R7C7" ], "outlineC" => "#666666", "width" => 0.8))
  end

  it "exports a rossini clue as a cosmetic arrow glyph" do
    expect(data["text"]).to include(include("cells" => [ "R7C0" ], "value" => "→", "size" => 0.7))
  end

  it "exports inequality signs as border-centred glyphs, rotated when stacked", :aggregate_failures do
    expect(data["text"]).to include(include("cells" => %w[R3C7 R3C8], "value" => "<", "size" => 0.3))
    expect(data["text"]).to include(include("cells" => %w[R6C6 R7C6], "value" => "∨", "size" => 0.3))
  end

  it "maps a lockout line to the native lockout field" do
    expect(data["lockout"]).to eq([ { "lines" => [ %w[R4C8 R4C9] ] } ])
  end

  it "maps a diamond shape with combined rotation angle and legacy size fallback", :aggregate_failures do
    shape = data["rectangle"].first
    expect(shape).to include("cells" => [ "R5C5" ], "value" => "X", "angle" => 75) # 45 (diamond) + 30
    expect(shape).to include("width" => 0.5, "height" => 0.5) # legacy `size` fills both dimensions
  end

  it "maps explicit shape width and height" do
    stretched = described_class.call(definition: stretched_definition).data
    expect(stretched["circle"].first).to include("width" => 1.5, "height" => 0.6)
  end

  it "omits the solution when include_solution is false" do
    no_sol = described_class.call(definition: definition, solution: solution, include_solution: false).data
    expect(no_sol).not_to have_key("solution")
  end

  it "warns about an unsupported custom global" do
    expect(result.warnings).to include(a_string_matching(/anti_diff.*value 3/))
  end

  describe "with a v4-native document" do
    # Plain methods, not lets: the outer group already carries five memoized
    # helpers, and these fixtures don't need per-example teardown.
    def v4_definition
      {
        "formatVersion" => 4,
        "grid" => { "rows" => 9, "cols" => 9 },
        "meta" => { "name" => "Native", "author" => "Ada" },
        "givenDigits" => { "r1c1" => 6 },
        "globals" => {
          "sudokuRules" => {},
          "diagonals" => { "positive" => true, "antiNegative" => true },
          "chess" => { "knight" => true },
          "antiKropki" => { "black" => true, "differences" => [ 1 ] },
          "antiXv" => { "v" => true },
          "disjointSets" => { "enabled" => true }
        },
        "constraints" => {
          "renbanLines" => [ { "cells" => %w[r9c6 r9c7] } ],
          "thermometers" => [ { "bulb" => "r5c1", "lines" => [ %w[r5c1 r5c2 r5c3], %w[r5c2 r6c2] ] } ],
          "arrows" => [ { "bulbCells" => [ "r3c3" ], "arrows" => [ %w[r3c3 r3c4] ] } ],
          "inequalities" => [ { "cells" => %w[r6c6 r7c6], "value" => ">" } ],
          "quadruples" => [ { "cells" => %w[r3c3 r3c4 r4c3 r4c4], "values" => [ 1, 2, 3 ] } ],
          "oddCells" => [ "r2c2" ],
          "killerCages" => [ { "cells" => %w[r1c8 r1c9], "sum" => 10 } ],
          "clones" => [ { "cells" => [ "r1c1" ], "copies" => [ { "dRow" => 1, "dCol" => 1 } ] } ],
          "xSums" => [ { "cell" => "r0c3", "value" => 20 } ],
          "littleKillers" => [ { "cell" => "r1c0", "value" => 5, "direction" => "down-right" } ],
          "rossini" => [ { "cell" => "r7c0", "direction" => "increasing" } ]
        },
        "cosmetics" => {
          "lines" => [ { "cells" => %w[r7c1 r7c2], "preset" => "line-1" } ],
          "linePresets" => [ { "id" => "line-1", "label" => "Grey", "style" => { "color" => "#ABCDEF", "strokeWidth" => 16, "opacity" => 1 } } ],
          "cellColors" => { "r1c6" => "color-1" },
          "cellColorPresets" => [ { "id" => "color-1", "label" => "Blue", "color" => "#123456" } ],
          "shapes" => [ { "pos" => { "x" => 5.5, "y" => 5.5 }, "content" => "X", "rotation" => 30, "preset" => "shape-1" } ],
          "shapePresets" => [ { "id" => "shape-1", "label" => "D", "style" => { "shapeType" => "diamond", "fillColor" => "none", "strokeColor" => "#333333", "width" => 0.5, "height" => 0.5, "textColor" => "#000000" } } ],
          "texts" => [ { "pos" => { "x" => 1.5, "y" => 10.5 }, "content" => "hi", "preset" => "text-1" } ],
          "textPresets" => [ { "id" => "text-1", "label" => "T", "style" => { "color" => "#112233", "fontSize" => 25 } } ],
          "cages" => [ { "cells" => %w[r8c1 r8c2], "sum" => 7, "preset" => "cage-1" } ],
          "cagePresets" => [ { "id" => "cage-1", "label" => "C", "style" => { "cageColor" => "#445566", "textColor" => "#778899" } } ]
        }
      }
    end

    def v4_data
      @v4_data ||= described_class.call(definition: v4_definition).data
    end

    it "reads 1-indexed meta and givens directly", :aggregate_failures do
      expect(v4_data).to include("size" => 9, "title" => "Native", "author" => "Ada")
      expect(v4_data["grid"][0][0]).to include("value" => 6, "given" => true)
    end

    it "maps grouped globals to flags, negatives, and the anti-diagonal line", :aggregate_failures do
      expect(v4_data).to include("diagonal+" => true, "antiknight" => true, "disjointgroups" => true)
      expect(v4_data).not_to include("diagonal-", "antiking", "nonconsecutive")
      expect(v4_data["negative"]).to contain_exactly("ratio", "xv", "difference")
      anti_diag = v4_data["line"].find { |l| l["outlineC"] == "#f06292" }
      expect(anti_diag["lines"]).to eq([ %w[R1C1 R2C2 R3C3 R4C4 R5C5 R6C6 R7C7 R8C8 R9C9] ])
    end

    it "rebuilds branching thermometer lines root-to-leaf from bulb/lines" do
      expect(v4_data["thermometer"].first["lines"]).to contain_exactly(%w[R5C1 R5C2 R5C3], %w[R5C1 R5C2 R6C2])
    end

    it "maps connectors from cell arrays", :aggregate_failures do
      expect(v4_data["quadruple"]).to eq([ { "cells" => %w[R3C3 R3C4 R4C3 R4C4], "values" => [ 1, 2, 3 ] } ])
      expect(v4_data["text"]).to include(include("cells" => %w[R6C6 R7C6], "value" => "∨", "size" => 0.3))
      expect(v4_data["arrow"]).to eq([ { "lines" => [ %w[R3C3 R3C4] ], "cells" => [ "R3C3" ] } ])
    end

    it "maps outer clues from ring cells (no o: prefix, direction renamed)", :aggregate_failures do
      expect(v4_data["xsum"]).to eq([ { "cell" => "R0C3", "value" => "20" } ])
      expect(v4_data["littlekillersum"]).to eq([ { "cell" => "R1C0", "direction" => "DR", "value" => "5" } ])
      expect(v4_data["text"]).to include(include("cells" => [ "R7C0" ], "value" => "→", "size" => 0.7))
    end

    it "maps cages, clones, and single-cell marks", :aggregate_failures do
      expect(v4_data["killercage"]).to eq([ { "cells" => %w[R1C8 R1C9], "value" => "10" } ])
      expect(v4_data["clone"].first).to include("cells" => [ "R1C1" ], "cloneCells" => [ "R2C2" ])
      expect(v4_data["odd"]).to eq([ { "cell" => "R2C2" } ])
      expect(v4_data["renban"]).to eq([ { "lines" => [ %w[R9C6 R9C7] ] } ])
    end

    it "styles cell colors, lines, and cages from slug-referenced presets", :aggregate_failures do
      expect(v4_data["grid"][0][5]).to eq("c" => "#123456")
      expect(v4_data["line"].find { |l| l["outlineC"] == "#ABCDEF" }).to include("lines" => [ %w[R7C1 R7C2] ], "width" => 0.25)
      expect(v4_data["cage"]).to eq([ { "cells" => %w[R8C1 R8C2], "value" => "7", "outlineC" => "#445566", "fontC" => "#778899" } ])
    end

    it "places free-positioned shapes and texts from document coordinates", :aggregate_failures do
      expect(v4_data["rectangle"].first).to include("cells" => [ "R5C5" ], "value" => "X", "angle" => 75, "width" => 0.5)
      expect(v4_data["text"]).to include(include("cells" => [ "R10C1" ], "value" => "hi", "fontC" => "#112233", "size" => 0.5))
    end

    def regioned_result
      @regioned_result ||= described_class.call(definition: {
        "formatVersion" => 4,
        "globals" => { "sudokuRules" => {} },
        "grid" => {
          "rows" => 4, "cols" => 4,
          "regions" => { "1" => %w[r1c1 r1c2 r2c1 r2c2], "2" => %w[r1c3 r1c4 r2c3] }
        }
      })
    end

    it "maps region-first grid.regions to per-cell region indices", :aggregate_failures do
      grid = regioned_result.data["grid"]
      expect(grid[0][0]["region"]).to eq(0)
      expect(grid[0][2]["region"]).to eq(1)
      expect(grid[1][3]).not_to have_key("region")
      expect(regioned_result.warnings).to include(a_string_matching(/belong to no region/))
    end
  end

  describe "preset opacity and per-instance colors" do
    # Cosmetic preset opacities bake into 8-digit hex (SudokuPad renders CSS
    # hex alpha; the encoder's own TRANSPARENT relies on it), and v4
    # per-instance setter colors apply wherever a color-bearing cosmetic is
    # already emitted; the rest aggregate into one fidelity warning.
    def colored_result
      @colored_result ||= described_class.call(definition: {
        "formatVersion" => 4,
        "globals" => { "sudokuRules" => {} },
        "grid" => { "rows" => 9, "cols" => 9 },
        "constraints" => {
          "renbanLines" => [ { "cells" => %w[r9c6 r9c7], "color" => "#112233" } ],
          "entropicLines" => [ { "cells" => %w[r7c1 r7c2], "color" => "#445566CC" } ],
          "slowThermometers" => [ { "bulb" => "r5c1", "lines" => [ %w[r5c1 r5c2] ], "color" => "#0000FF", "bulbColor" => "#FF0000" } ],
          "thermometers" => [ { "bulb" => "r6c1", "lines" => [ %w[r6c1 r6c2] ], "color" => "#123123" } ],
          "killerCages" => [ { "cells" => %w[r1c8 r1c9], "sum" => 10, "cageColor" => "#00FF00" } ],
          "inequalities" => [ { "cells" => %w[r2c6 r2c7], "value" => "<", "color" => "#AA00AA" } ],
          "oddCells" => [ "r2c2", { "cell" => "r3c3", "color" => "#99999980" } ],
          "countingCircles" => [ { "cell" => "r6c6", "color" => "#FFD700", "outlineColor" => "#004400" } ],
          "rowIndexCells" => [ { "cell" => "r1c1", "color" => "#EE8800" }, "r2c1" ],
          "xSums" => [ { "cell" => "r0c3", "value" => 20, "color" => "#775577" } ],
          "rossini" => [ { "cell" => "r7c0", "direction" => "increasing", "color" => "#557755" } ]
        },
        "cosmetics" => {
          "lines" => [ { "cells" => %w[r8c1 r8c2], "preset" => "line-1" } ],
          "linePresets" => [ { "id" => "line-1", "style" => { "color" => "#ABCDEF", "strokeWidth" => 16, "opacity" => 0.25 } } ],
          "cellColors" => { "r1c6" => "color-1" },
          "cellColorPresets" => [ { "id" => "color-1", "color" => "#123456", "opacity" => 0.5 } ],
          "shapes" => [ { "pos" => { "x" => 5.5, "y" => 5.5 }, "content" => "X", "preset" => "shape-1" } ],
          "shapePresets" => [ {
            "id" => "shape-1",
            "style" => {
              "shapeType" => "circle", "fillColor" => "#11223380", "strokeColor" => "#333333",
              "width" => 0.5, "height" => 0.5, "textColor" => "#000000",
              "fillOpacity" => 0.5, "strokeOpacity" => 1, "textOpacity" => 0
            }
          } ],
          "texts" => [ { "pos" => { "x" => 1.5, "y" => 10.5 }, "content" => "hi", "preset" => "text-1" } ],
          "textPresets" => [ { "id" => "text-1", "style" => { "color" => "#112233", "fontSize" => 25, "opacity" => 0.25 } } ],
          "cages" => [ { "cells" => %w[r8c5 r8c6], "preset" => "cage-1" } ],
          "cagePresets" => [ { "id" => "cage-1", "style" => { "cageColor" => "#445566", "textColor" => "#778899", "cageOpacity" => 0.5, "textOpacity" => 1 } } ]
        }
      })
    end

    def colored_data = colored_result.data

    it "bakes preset opacities into 8-digit hex, collapsing full opacity", :aggregate_failures do
      expect(colored_data["grid"][0][5]).to eq("c" => "#12345680")
      expect(colored_data["line"]).to include(include("lines" => [ %w[R8C1 R8C2] ], "outlineC" => "#ABCDEF40"))
      expect(colored_data["text"]).to include(include("value" => "hi", "fontC" => "#11223340"))
      expect(colored_data["cage"].first).to include("outlineC" => "#44556680", "fontC" => "#778899")
    end

    it "multiplies a preset opacity into an already 8-digit color", :aggregate_failures do
      shape = colored_data["circle"].find { |c| c["value"] == "X" }
      expect(shape).to include("baseC" => "#11223340")   # 0x80 alpha * 0.5
      expect(shape).to include("outlineC" => "#333333")  # opacity 1 stays 6-digit
      expect(shape).to include("fontC" => "#00000000")   # opacity 0
    end

    it "applies instance colors to line cosmetics, passing 8-digit hex through", :aggregate_failures do
      expect(colored_data["line"]).to include(include("lines" => [ %w[R9C6 R9C7] ], "outlineC" => "#112233", "width" => 0.4))
      expect(colored_data["line"]).to include(include("lines" => [ %w[R7C1 R7C2] ], "outlineC" => "#445566CC"))
    end

    it "colors a slow thermometer's tube and bulb separately", :aggregate_failures do
      expect(colored_data["line"]).to include(include("lines" => [ %w[R5C1 R5C2] ], "outlineC" => "#0000FF"))
      expect(colored_data["circle"]).to include(include("cells" => [ "R5C1" ], "outlineC" => "#FF0000"))
    end

    it "colors counting-circle rings with fill from the generic color", :aggregate_failures do
      ring = colored_data["circle"].find { |c| c["cells"] == [ "R6C6" ] }
      expect(ring).to include("baseC" => "#FFD700", "outlineC" => "#004400")
    end

    it "reads object-form single-cell marks and colored index tints", :aggregate_failures do
      expect(colored_data["odd"]).to contain_exactly({ "cell" => "R2C2" }, { "cell" => "R3C3" })
      expect(colored_data["grid"][0][0]).to eq("c" => "#EE8800")   # setter color beats the tint
      expect(colored_data["grid"][1][0]).to eq("c" => "#FFD9D9")   # plain mark keeps the tint
      expect(colored_data["rowindexer"]).to eq([ { "cells" => %w[R1C1 R2C1] } ])
    end

    it "colors outer-clue text fallbacks", :aggregate_failures do
      expect(colored_data["text"]).to include(include("value" => "20", "fontC" => "#775577"))
      expect(colored_data["text"]).to include(include("value" => "→", "fontC" => "#557755"))
      expect(colored_data["text"]).to include(include("value" => "<", "fontC" => "#AA00AA"))
    end

    it "aggregates one warning naming the unexportable colored constraints", :aggregate_failures do
      warning = colored_result.warnings.find { |w| w.include?("no SudokuPad equivalent") }
      expect(warning).to include("thermometers", "killerCages", "oddCells")
      expect(warning).not_to include("renbanLines", "slowThermometers", "countingCircles", "rowIndexCells")
      expect(colored_result.warnings.count { |w| w.include?("no SudokuPad equivalent") }).to eq(1)
    end
  end

  describe "fog of war" do
    def fog_definition(enabled: true, lights: [ "r1c1", "r5c5" ])
      {
        "formatVersion" => 4,
        "grid" => { "rows" => 9, "cols" => 9 },
        "globals" => { "sudokuRules" => {}, "fog" => { "enabled" => enabled } },
        "constraints" => { "fogLights" => lights }
      }
    end

    it "emits foglight cells and an empty fogofwar", :aggregate_failures do
      data = described_class.call(definition: fog_definition, solution: solution).data
      expect(data["foglight"]).to eq(%w[R1C1 R5C5])
      expect(data["fogofwar"]).to eq([])
    end

    it "forces the embedded solution even when include_solution is false" do
      data = described_class.call(definition: fog_definition, solution: solution, include_solution: false).data
      expect(data["solution"][0, 2]).to eq(%w[1 2])
    end

    it "warns when fog has no solution to embed" do
      result = described_class.call(definition: fog_definition, solution: nil)
      expect(result.warnings).to include(a_string_matching(/Fog needs an embedded solution/))
    end

    it "emits no fog keys when the toggle is off", :aggregate_failures do
      data = described_class.call(definition: fog_definition(enabled: false), solution: solution, include_solution: false).data
      expect(data).not_to have_key("foglight")
      expect(data).not_to have_key("fogofwar")
      expect(data).not_to have_key("solution")
    end

    it "reads object-form light entries and flags their unexportable colors", :aggregate_failures do
      definition = fog_definition(lights: [ { "cell" => "r2c2", "color" => "#FF0000" } ])
      result = described_class.call(definition: definition, solution: solution)
      expect(result.data["foglight"]).to eq([ "R2C2" ])
      expect(result.warnings).to include(a_string_matching(/fogLights/))
    end
  end
end
