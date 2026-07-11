module PuzzleDefinition
  # Hand-maintained Ruby mirror of the puzzle format v4 document key tables
  # derived in the frontend registry (app/src/constraints/registry.ts). The
  # registry test ("pins the document keys the stored format depends on" /
  # "derives the globals group document shapes" in registry.test.ts) pins the
  # exact same strings on the TS side; the parity harness
  # (`bin/rails puzzle_format:verify`) catches drift between the two.
  #
  # Hash insertion order is meaningful: it mirrors the registry DEFS order,
  # which is the canonical serialization order of v4 document keys.
  module JsonKeys
    # Constraint/cosmetic type -> its document key. Local constraint and
    # cosmetic types key their sections under `constraints`/`cosmetics`;
    # global CATEGORY types key their group under `globals`.
    TYPE_TO_JSON_KEY = {
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
      "average_arrow" => "averageArrows",
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
      "house" => "houses",
      "clone" => "clones",
      "x_sums" => "xSums",
      "sandwich_sums" => "sandwichSums",
      "skyscrapers" => "skyscrapers",
      "little_killers" => "littleKillers",
      "numbered_rooms" => "numberedRooms",
      "battlefield" => "battlefield",
      "next_to_nine" => "nextToNine",
      "rossini" => "rossini",
      "sudoku_rules" => "sudokuRules",
      "diagonals" => "diagonals",
      "chess" => "chess",
      "anti_kropki" => "antiKropki",
      "anti_xv" => "antiXv",
      "disjoint_sets" => "disjointSets",
      "fog" => "fog",
      "fog_lights" => "fogLights",
      "cosmetic_line" => "lines",
      "cosmetic_border" => "borders",
      "cell_color" => "cellColors",
      "shape" => "shapes",
      "text" => "texts",
      "cosmetic_cage" => "cages"
    }.freeze

    JSON_KEY_TO_TYPE = TYPE_TO_JSON_KEY.invert.freeze

    # Cosmetic kind -> the sibling presets array key in the `cosmetics` section.
    PRESETS_KEY_BY_TYPE = {
      "cosmetic_line" => "linePresets",
      "cosmetic_border" => "borderPresets",
      "cell_color" => "cellColorPresets",
      "shape" => "shapePresets",
      "text" => "textPresets",
      "cosmetic_cage" => "cagePresets"
    }.freeze

    # Globals groups (one per UI panel): the group's document key under
    # `globals`, its variant toggle fields (toggle key -> variant type string),
    # and its custom-value fields (document field -> CustomGlobalConstraint
    # type). Mirrors GLOBAL_GROUPS_JSON in registry.ts.
    GLOBAL_GROUPS = [
      {
        # Key presence carries the rule; `enabled: false` soft-disables and
        # `custom: true` swaps the automatic row/column houses for
        # author-defined ones.
        type: "sudoku_rules",
        key: "sudokuRules",
        variants: [
          { type: "sudoku_rules", key: "enabled" },
          { type: "sudoku_custom_houses", key: "custom" }
        ],
        custom_values: {}
      },
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
        variants: [
          { type: "kings_move", key: "king" },
          { type: "knights_move", key: "knight" }
        ],
        custom_values: {}
      },
      {
        type: "anti_kropki",
        key: "antiKropki",
        variants: [
          { type: "nonconsecutive", key: "white" },
          { type: "anti_black_kropki", key: "black" }
        ],
        custom_values: { "differences" => "anti_diff", "ratios" => "anti_ratio" }
      },
      {
        type: "anti_xv",
        key: "antiXv",
        variants: [
          { type: "anti_x", key: "x" },
          { type: "anti_v", key: "v" }
        ],
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
    ].freeze

    # Category routing (the frontend's toolboxCategory, collapsed to what the
    # serialization boundary needs): which document shape a type's entry uses.
    SINGLE_CELL_TYPES = %w[
      odd_cells even_cells minimums maximums counting_circles
      row_index_cells col_index_cells fog_lights
    ].freeze
    CONNECTOR_TYPES = %w[difference_dots ratio_dots xv inequality quadruples].freeze
    OUTER_CLUE_TYPES = %w[
      x_sums sandwich_sums skyscrapers little_killers numbered_rooms
      battlefield next_to_nine rossini
    ].freeze
    GLOBAL_TYPES = GLOBAL_GROUPS.map { |group| group[:type] }.freeze
    COSMETIC_TYPES = PRESETS_KEY_BY_TYPE.keys.freeze
    # Thermo-drawn types serialize as { bulb, lines } rather than { cells }.
    THERMO_TYPES = %w[thermometer slow_thermometer].freeze

    CATEGORY_BY_TYPE = TYPE_TO_JSON_KEY.keys.index_with do |type|
      if SINGLE_CELL_TYPES.include?(type) then :single_cell
      elsif CONNECTOR_TYPES.include?(type) then :connector
      elsif OUTER_CLUE_TYPES.include?(type) then :outer
      elsif GLOBAL_TYPES.include?(type) then :global
      elsif COSMETIC_TYPES.include?(type) then :cosmetic
      else
        :instance
      end
    end.freeze

    # :single_cell | :connector | :outer | :global | :cosmetic | :instance
    def self.category(type)
      CATEGORY_BY_TYPE[type]
    end
  end
end
