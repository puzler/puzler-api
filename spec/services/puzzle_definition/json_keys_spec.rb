require "rails_helper"

RSpec.describe PuzzleDefinition::JsonKeys do
  # These strings are pinned on the frontend too (registry.test.ts, 'pins the
  # document keys the stored format depends on') — every stored v4 definition
  # depends on them, so renames are format migrations, not refactors.
  let(:pinned_type_keys) do
    {
      "renban" => "renbanLines",
      "german_whispers" => "germanWhispers",
      "dutch_whispers" => "dutchWhispers",
      "palindrome" => "palindromes",
      "region_sum" => "regionSumLines",
      "entropic_lines" => "entropicLines",
      "modular_lines" => "modularLines",
      "nabner_lines" => "nabnerLines",
      "zipper_lines" => "zipperLines",
      "between_lines" => "betweenLines",
      "lockout_lines" => "lockoutLines",
      "thermometer" => "thermometers",
      "slow_thermometer" => "slowThermometers",
      "arrow" => "arrows",
      "difference_dots" => "differenceDots",
      "ratio_dots" => "ratioDots",
      "xv" => "xv",
      "inequality" => "inequalities",
      "quadruples" => "quadruples",
      "odd_cells" => "oddCells",
      "even_cells" => "evenCells",
      "minimums" => "minimums",
      "maximums" => "maximums",
      "counting_circles" => "countingCircles",
      "row_index_cells" => "rowIndexCells",
      "col_index_cells" => "colIndexCells",
      "killer_cage" => "killerCages",
      "extra_regions" => "extraRegions",
      "clone" => "clones",
      "x_sums" => "xSums",
      "sandwich_sums" => "sandwichSums",
      "skyscrapers" => "skyscrapers",
      "little_killers" => "littleKillers",
      "numbered_rooms" => "numberedRooms",
      "battlefield" => "battlefield",
      "next_to_nine" => "nextToNine",
      "rossini" => "rossini",
      "diagonals" => "diagonals",
      "chess" => "chess",
      "anti_kropki" => "antiKropki",
      "anti_xv" => "antiXv",
      "disjoint_sets" => "disjointSets",
      "fog" => "fog",
      "fog_lights" => "fogLights",
      "cosmetic_line" => "lines",
      "cell_color" => "cellColors",
      "shape" => "shapes",
      "text" => "texts",
      "cosmetic_cage" => "cages"
    }
  end

  let(:pinned_presets_keys) do
    {
      "cosmetic_line" => "linePresets",
      "cell_color" => "cellColorPresets",
      "shape" => "shapePresets",
      "text" => "textPresets",
      "cosmetic_cage" => "cagePresets"
    }
  end

  let(:pinned_global_groups) do
    [
      {
        type: "diagonals",
        key: "diagonals",
        variants: [
          { type: "positive_diagonal", key: "positive" },
          { type: "negative_diagonal", key: "negative" },
          { type: "anti_positive_diagonal", key: "antiPositive" },
          { type: "anti_negative_diagonal", key: "antiNegative" }
        ],
        custom_values: {}
      },
      {
        type: "chess",
        key: "chess",
        variants: [ { type: "kings_move", key: "king" }, { type: "knights_move", key: "knight" } ],
        custom_values: {}
      },
      {
        type: "anti_kropki",
        key: "antiKropki",
        variants: [ { type: "nonconsecutive", key: "white" }, { type: "anti_black_kropki", key: "black" } ],
        custom_values: { "differences" => "anti_diff", "ratios" => "anti_ratio" }
      },
      {
        type: "anti_xv",
        key: "antiXv",
        variants: [ { type: "anti_x", key: "x" }, { type: "anti_v", key: "v" } ],
        custom_values: { "sums" => "anti_sum" }
      },
      {
        type: "disjoint_sets",
        key: "disjointSets",
        variants: [ { type: "disjoint_sets", key: "enabled" } ],
        custom_values: {}
      },
      {
        type: "fog",
        key: "fog",
        variants: [ { type: "fog", key: "enabled" } ],
        custom_values: {}
      }
    ]
  end

  it "pins the type -> document key table (and its canonical order)", :aggregate_failures do
    expect(described_class::TYPE_TO_JSON_KEY).to eq(pinned_type_keys)
    expect(described_class::TYPE_TO_JSON_KEY.keys).to eq(pinned_type_keys.keys)
  end

  it "pins the cosmetic presets key table" do
    expect(described_class::PRESETS_KEY_BY_TYPE).to eq(pinned_presets_keys)
  end

  it "keeps the key table invertible" do
    expect(described_class::JSON_KEY_TO_TYPE.size).to eq(described_class::TYPE_TO_JSON_KEY.size)
  end

  it "pins the globals group document shapes" do
    expect(described_class::GLOBAL_GROUPS).to eq(pinned_global_groups)
  end

  it "routes every document type to a category" do
    expect(described_class::TYPE_TO_JSON_KEY.keys.map { |t| described_class.category(t) }).to all(be_present)
  end

  it "routes types to the category their document shape depends on" do
    expect(%w[odd_cells quadruples rossini anti_kropki cell_color thermometer renban unknown].map { |t| described_class.category(t) })
      .to eq([ :single_cell, :connector, :outer, :global, :cosmetic, :instance, :instance, nil ])
  end
end
