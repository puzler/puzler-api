require "rails_helper"

RSpec.describe Fpuzzles::Encoder do
  # A definition exercising one of each constraint family (mirrors the frontend
  # converter's coverage; full byte-parity with the frontend is validated
  # separately). String keys, as stored in the jsonb.
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



  it "maps meta, 1-indexed givens, and the row-major solution", :aggregate_failures do
    expect(data).to include("size" => 9, "title" => "Rich", "author" => "fallback")
    expect(data["grid"][0][0]).to include("value" => 1, "given" => true)
    expect(data["solution"][0, 2]).to eq(%w[1 2])
  end

  it "raises on a non-square grid" do
    expect { described_class.call(definition: { "grid" => { "rows" => 9, "cols" => 6 } }) }
      .to raise_error(Fpuzzles::UnsupportedGrid)
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

  it "maps a diamond shape with combined rotation angle", :aggregate_failures do
    shape = data["rectangle"].first
    expect(shape).to include("cells" => [ "R5C5" ], "value" => "X", "angle" => 75) # 45 (diamond) + 30
  end

  it "omits the solution when include_solution is false" do
    no_sol = described_class.call(definition: definition, solution: solution, include_solution: false).data
    expect(no_sol).not_to have_key("solution")
  end

  it "warns about an unsupported custom global" do
    expect(result.warnings).to include(a_string_matching(/anti_diff.*value 3/))
  end
end
