module Scl
  class Error < StandardError; end
  class UnsupportedGrid < Error; end

  # Builds the SudokuPad-native SCL object (and fidelity warnings) from a
  # Puzler `definition` (the stored SerializedPuzzle jsonb) plus an optional
  # solution. Reads puzzle format v4 — every definition is normalized through
  # PuzzleDefinition::Migrator.v3_to_v4 at entry, exactly like Fpuzzles::Encoder.
  #
  # SCL is SudokuPad's own low-level rendering format: `cells` (2D row-major,
  # 0-indexed), `regions`, `cages`, plus drawn primitives (`lines`, `arrows`,
  # `overlays`, `underlays`) and `foglight`. Its only logic-bearing pieces are
  # regions, givens, `unique` cages, foglight, and the `solution:` meta-cage —
  # everything else we draw ourselves the way Puzler renders it, so nothing is
  # silently dropped (the old f-puzzles importer limitation this replaces).
  #
  # Coordinates (browser-verified against sudokupad.app v0.611.0): geometry is
  # `[row, col]`, 0-indexed; INTEGER coords are gridline intersections and cell
  # (r, c)'s CENTER is [r + 0.5, c + 0.5]. Document keys are 1-indexed, so the
  # center of doc key r1c1 is [0.5, 0.5]. Cell lists (cages/regions/foglight)
  # use integer CELL coords [r, c]. Thickness/fontSize are px at cellSize 64 —
  # 1:1 with Puzler's own px values; overlay width/height are cell units (px/64).
  #
  # Layering (from SudokuPad's SVG group order): underlays < cell colors <
  # lines/arrows < cages < gridlines < overlays < digits. So cell-sized fills
  # go in `underlays` and anything that must sit on top of gridlines (dots,
  # glyphs, void covers) goes in `overlays`.
  #
  # Metadata travels as "meta-cages" (cages with no cells, value "title: ..."):
  # the canonical SudokuPad mechanism, browser-verified. The solution meta-cage
  # is a row-major digit string over the full rows x cols grid.
  #
  # Per-puzzle player settings CANNOT be embedded in the payload — SudokuPad
  # only reads them from `?setting-<name>=<value>` URL params (framework.js
  # getQuerySettings). The encoder surfaces them in Result#url_params for the
  # link builder to append.
  #
  # EXPORT IS THEME-AGNOSTIC: styling comes from Puzler's default constraint
  # styles (ported from app/src/constraints/definitions and the grid layer
  # components) and the author's cosmetic presets — never a user theme.
  class Encoder
    include PuzzleDefinition::DocHelpers

    Result = Struct.new(:data, :warnings, :url_params)

    CELL_PX = 64
    WHITE = "#FFFFFF".freeze
    BLACK = "#000000".freeze
    TRANSPARENT = "#00000000".freeze
    # Solution placeholder for cells without a solved digit (SudokuPad's
    # checker skips it; same convention as its penpa importer).
    SOLUTION_SKIP = "?".freeze

    INDEX_CELL_COLOR = { "row" => "#ffc8c8", "col" => "#b4ebc3", "both" => "#fff5aa" }.freeze
    INDEX_CELL_OPACITY = 0.7

    # Constraint line colors/width (frontend registry defaults; stroke 8px).
    CONSTRAINT_LINE_COLOR = {
      "renban" => "#f067f0", "german_whispers" => "#67f067", "dutch_whispers" => "#ff6f00",
      "palindrome" => "#c0c0c0", "region_sum" => "#00c8ff", "entropic_lines" => "#fa9678",
      "modular_lines" => "#00b5ad", "nabner_lines" => "#f0c300", "zipper_lines" => "#ac8aff"
    }.freeze
    CONSTRAINT_LINE_WIDTH = 8

    THERMO_COLOR = "#aaaaaa".freeze
    THERMO_STROKE_WIDTH = 12
    THERMO_BULB_RADIUS = 18

    ARROW_COLOR = "#aaaaaa".freeze
    ARROW_STROKE_WIDTH = 2.5
    ARROW_BULB_RADIUS = 27
    ARROW_HEAD_LENGTH = 11
    # Puzler draws the average-arrow inner ring dashed; SCL overlays have no
    # dash support, so it exports as a solid inner ring at the same inset.
    AVERAGE_ARROW_BULB_INSET = 5

    BETWEEN_LINE_COLOR = "#bbbbbb".freeze
    BETWEEN_LINE_WIDTH = 2
    BETWEEN_END_RADIUS = 26
    LOCKOUT_DIAMOND_STROKE = "#4a90d9".freeze

    MINMAX_TINT = "#f0f0f0".freeze
    MINMAX_CHEVRON_COLOR = "#333333".freeze
    ODD_EVEN_FILL = "#bbbbbb".freeze
    COUNTING_CIRCLE_OUTLINE = "#666666".freeze
    EXTRA_REGION_FILL = "#dddddd".freeze
    CLONE_FILL = "#cccccc".freeze

    DOT_DIAMETER = 0.25
    CONNECTOR_GLYPH_SIZE = 19.2
    QUAD_DIAMETER = 0.5

    OUTER_FONT_LARGE = 41.6
    OUTER_FONT_SMALL = 32
    OUTER_SMALL_TYPES = %w[little_killers next_to_nine].freeze

    DIAGONAL_COLOR = "#93c5fd".freeze
    ANTI_DIAGONAL_COLOR = "#f87171".freeze
    DIAGONAL_WIDTH = 2
    DIAGONAL_OPACITY = 0.85

    LITTLE_KILLER_DIR = {
      "up-left" => [ -1, -1 ], "up-right" => [ -1, 1 ],
      "down-left" => [ 1, -1 ], "down-right" => [ 1, 1 ]
    }.freeze

    def self.call(definition:, solution: nil, include_solution: true, fallback_author: nil)
      new(definition, solution, include_solution, fallback_author).call
    end

    def initialize(definition, solution, include_solution, fallback_author)
      @raw = (definition || {}).deep_stringify_keys
      @solution = solution
      @include_solution = include_solution
      @fallback_author = fallback_author
      @warnings = []
      @unchecked_rules = []
      @url_params = {}
      @scl = {}
    end

    def call
      grid = @raw["grid"] || {}
      rows = grid["rows"]
      cols = grid["cols"]
      unless rows.is_a?(Integer) && rows.positive? && cols.is_a?(Integer) && cols.positive?
        raise UnsupportedGrid, "SudokuPad export needs a grid with valid dimensions."
      end

      @def = PuzzleDefinition::Migrator.v3_to_v4(@raw)
      @rows = @def["grid"]["rows"]
      @cols = @def["grid"]["cols"]

      # Fog puzzles need the embedded solution to clear fog in SudokuPad, so
      # it is always included regardless of the author's export preference.
      if fog_enabled?
        @include_solution = true
        if @solution.blank?
          @warnings << "Fog needs an embedded solution to work in SudokuPad; set a solution before exporting."
        end
      end

      @scl["cellSize"] = CELL_PX
      build_grid(@def["grid"])
      build_meta_cages
      build_settings
      build_globals
      build_fog
      build_single_cell_marks
      build_connectors
      build_outer_clues
      build_constraint_instances
      build_cosmetic_instances

      unless @unchecked_rules.empty?
        @warnings << "SudokuPad shows #{@unchecked_rules.uniq.join(', ')} in the rules but does not conflict-check them."
      end
      Result.new(@scl, @warnings, @url_params)
    end

    private

    # ── grid / cells / regions / voids ──────────────────────────────────────

    def build_grid(grid)
      color_by_id = (cosmetics["cellColorPresets"] || []).to_h { |p| [ p["id"], blend_opacity(p["color"], p["opacity"]) ] }

      # `grid.regions` is region-first (label -> complete 1-indexed cell list).
      # SCL regions follow sorted label order. Overlapping regions are emitted
      # as-is: SudokuPad outlines each region's boundary, and the union of
      # boundaries is exactly Puzler's own label-set border rule.
      regions = grid["regions"]
      regioned = nil
      if regions.is_a?(Hash) && !regions.empty?
        regioned = Set.new
        @scl["regions"] = regions.keys.sort.map do |label|
          Array(regions[label]).map do |cell|
            regioned << cell
            rc(cell)
          end
        end
      end

      row_index = single_cell_entries("row_index_cells").to_h
      col_index = single_cell_entries("col_index_cells").to_h
      cell_colors = cosmetics["cellColors"] || {}
      givens = @def["givenDigits"] || {}

      digits = grid["digits"]
      if digits.is_a?(Numeric) && digits != [ @rows, @cols ].max
        @warnings << "SudokuPad does not enforce a custom digit range; this puzzle's 1-#{digits} is stated in the rules only."
      end

      @void_cells = []
      @scl["cells"] = Array.new(@rows) do |r|
        Array.new(@cols) do |c|
          key = "r#{r + 1}c#{c + 1}"
          cell = {}
          given = givens[key]
          unless given.nil?
            cell["value"] = given
            cell["given"] = true
          end
          # With regions painted, a regionless cell is VOID (dead space).
          @void_cells << key if regioned && !regioned.include?(key)
          color_id = cell_colors[key]
          if color_id && color_by_id.key?(color_id)
            cell["c"] = color_by_id[color_id]
          else
            is_row = row_index.key?(key)
            is_col = col_index.key?(key)
            # A per-instance setter color on either index mark beats the tint.
            setter = (is_row && row_index[key]["color"]) || (is_col && col_index[key]["color"]) || nil
            tint = ->(kind) { setter || blend_opacity(INDEX_CELL_COLOR[kind], INDEX_CELL_OPACITY) }
            cell["c"] = tint.call("both") if is_row && is_col
            cell["c"] = tint.call("row") if is_row && !is_col
            cell["c"] = tint.call("col") if is_col && !is_row
          end
          cell
        end
      end

      build_voids
    end

    # Void cells stay in the cells array (SCL has no dead-cell primitive) and
    # get a white cover overlay hiding their gridlines (overlays render above
    # the grid layer — an underlay would sit below it; browser-verified).
    # Per-edge sizing: covers EXTEND a hair toward neighboring void cells and
    # past the grid edge (so anti-aliasing at shared cover edges can't let a
    # gridline peek through), but INSET from live cells by half of SudokuPad's
    # 3px region outline — the `box` outline straddles the boundary in the
    # cages layer BELOW overlays, so a full-size cover would eat its void-side
    # half and leave region borders looking thin next to voids.
    VOID_OVERLAP = 0.05
    VOID_BORDER_INSET = 1.5 / CELL_PX.to_f

    def build_voids
      return if @void_cells.empty?

      voids = @void_cells.to_set
      @void_cells.each do |key|
        row, col = parse_key(key)
        up = void_edge_delta(voids, row - 1, col)
        down = void_edge_delta(voids, row + 1, col)
        left = void_edge_delta(voids, row, col - 1)
        right = void_edge_delta(voids, row, col + 1)
        push("overlays", {
          "center" => [ coord(row - 0.5 + (down - up) / 2.0), coord(col - 0.5 + (right - left) / 2.0) ],
          "width" => coord(1 + left + right), "height" => coord(1 + up + down),
          "backgroundColor" => WHITE, "borderSize" => 0
        })
      end
      @warnings << "Void cells export as blank dead cells; SudokuPad still allows typing in them."
    end

    # How far the cover reaches past (positive) or stops short of (negative)
    # the cell edge facing the 1-indexed neighbor (row, col).
    def void_edge_delta(voids, row, col)
      outside = row < 1 || row > @rows || col < 1 || col > @cols
      return VOID_OVERLAP if outside || voids.include?("r#{row}c#{col}")

      -VOID_BORDER_INSET
    end

    # ── metadata / solution (meta-cages) ─────────────────────────────────────

    def build_meta_cages
      meta = @def["meta"] || {}
      author = present?(meta["author"]) ? meta["author"] : @fallback_author
      meta_cage("title", meta["name"])
      meta_cage("author", author)
      meta_cage("rules", meta["rules"])
      meta_cage("solution", solution_string)
    end

    def meta_cage(name, value)
      push("cages", { "value" => "#{name}: #{value}" }) if present?(value)
    end

    # The solution argument comes from the version's own column (internal
    # board-snapshot keys, still 0-indexed), not from the v4 document. SCL
    # solutions are one character per cell, row-major over the full grid.
    def solution_string
      return nil unless @include_solution && @solution.is_a?(Hash) && !@solution.empty?

      if @solution.values.any? { |digit| digit.to_i > 9 }
        @warnings << "SudokuPad solution checking supports single-digit cells only; this solution has digits above 9 and was not embedded."
        return nil
      end

      chars = Array.new(@rows * @cols, SOLUTION_SKIP)
      @solution.each do |key, digit|
        row, col = parse_key(key)
        chars[row * @cols + col] = digit.to_s if row < @rows && col < @cols
      end
      chars.join
    end

    # ── settings (metadata flags + URL params) ───────────────────────────────

    # SudokuPad auto-generates full row/column check cages unless the puzzle's
    # metadata carries `norowcol: true` (a BOOLEAN on the top-level metadata
    # object — meta-cage values arrive as strings and would fail its
    # `!== true` check). Custom-house puzzles rely on that flag: rows/columns
    # stop being checked while the invisible house cages and the region cages
    # keep conflict-checking correctly. Rules-off puzzles additionally turn
    # the player's conflict checker off entirely via a `setting-*` URL param
    # (SudokuPad only reads settings from the URL, never the payload).
    def build_settings
      sudoku_rules = global_group("sudokuRules")
      enabled = globals.key?("sudokuRules") && sudoku_rules["enabled"] != false
      custom = sudoku_rules["custom"] == true
      return if enabled && !custom

      @scl["metadata"] = { "norowcol" => true }
      return if enabled

      @url_params["setting-conflictchecker"] = "false"
      @warnings << "SudokuPad's automatic conflict highlighting is turned off for this link (this puzzle has no sudoku rules)."
    end

    # ── globals ──────────────────────────────────────────────────────────────

    def build_globals
      diagonals = global_group("diagonals")
      push_diagonal("positive", DIAGONAL_COLOR) if diagonals["positive"] == true
      push_diagonal("negative", DIAGONAL_COLOR) if diagonals["negative"] == true
      push_diagonal("positive", ANTI_DIAGONAL_COLOR) if diagonals["antiPositive"] == true
      push_diagonal("negative", ANTI_DIAGONAL_COLOR) if diagonals["antiNegative"] == true

      chess = global_group("chess")
      anti_kropki = global_group("antiKropki")
      anti_xv = global_group("antiXv")
      @unchecked_rules << "anti-king" if chess["king"] == true
      @unchecked_rules << "anti-knight" if chess["knight"] == true
      @unchecked_rules << "negative white kropki" if anti_kropki["white"] == true
      @unchecked_rules << "negative black kropki" if anti_kropki["black"] == true
      @unchecked_rules << "negative XV" if anti_xv["x"] == true || anti_xv["v"] == true
      @unchecked_rules << "disjoint groups" if global_group("disjointSets")["enabled"] == true
      custom_globals.each { |cg| @unchecked_rules << "#{cg[:type].tr('_', ' ')} (#{cg[:value]})" }
    end

    # Puzler draws the main diagonals blue and the anti diagonals red, both
    # corner to corner. Positive runs bottom-left to top-right.
    def push_diagonal(kind, color)
      way_points =
        if kind == "positive"
          [ [ @rows, 0 ], [ 0, @cols ] ]
        else
          [ [ 0, 0 ], [ @rows, @cols ] ]
        end
      push("lines", {
        "wayPoints" => way_points,
        "color" => blend_opacity(color, DIAGONAL_OPACITY),
        "thickness" => DIAGONAL_WIDTH
      })
    end

    # ── fog ──────────────────────────────────────────────────────────────────

    # SCL `foglight` cells start revealed — exactly Puzler's single-cell fog
    # lights (browser-verified; correct digits then clear 3x3 as usual).
    def build_fog
      return unless fog_enabled?

      lights = single_cell_entries("fog_lights")
      @scl["foglight"] = lights.map { |key, _| rc(key) }
    end

    # ── single-cell marks ────────────────────────────────────────────────────

    def build_single_cell_marks
      single_cell_entries("odd_cells").each do |key, colors|
        push("underlays", {
          "center" => center(key), "width" => 0.75, "height" => 0.75, "rounded" => true,
          "backgroundColor" => colors["color"] || ODD_EVEN_FILL
        })
      end
      single_cell_entries("even_cells").each do |key, colors|
        push("underlays", {
          "center" => center(key), "width" => 0.7, "height" => 0.7,
          "backgroundColor" => colors["color"] || ODD_EVEN_FILL
        })
      end
      single_cell_entries("minimums").each { |key, colors| build_min_max(key, colors, inward: true) }
      single_cell_entries("maximums").each { |key, colors| build_min_max(key, colors, inward: false) }
      # Counting circles: generic `color` reaches the fill only, the outline
      # changes via outlineColor (frontend rule).
      single_cell_entries("counting_circles").each do |key, colors|
        fill = colors["fillColor"] || colors["color"]
        push("overlays", {
          "center" => center(key), "width" => 0.8, "height" => 0.8, "rounded" => true,
          "backgroundColor" => fill || "none",
          "borderColor" => colors["outlineColor"] || COUNTING_CIRCLE_OUTLINE,
          "borderSize" => 2
        })
      end
    end

    # A min/max cell is a tinted cell with a chevron at each edge: pointing
    # into the cell for minimums, out of it for maximums (MinMaxLayer.vue).
    def build_min_max(key, colors, inward:)
      push("underlays", {
        "center" => center(key), "width" => 1, "height" => 1,
        "backgroundColor" => colors["backgroundColor"] || colors["color"] || MINMAX_TINT
      })
      r, c = center(key)
      chevron = colors["chevronColor"] || MINMAX_CHEVRON_COLOR
      glyphs =
        if inward
          { top: "∨", bottom: "∧", left: ">", right: "<" }
        else
          { top: "∧", bottom: "∨", left: "<", right: ">" }
        end
      offsets = { top: [ -0.4, 0 ], bottom: [ 0.4, 0 ], left: [ 0, -0.4 ], right: [ 0, 0.4 ] }
      offsets.each do |edge, (dr, dc)|
        push("overlays", {
          "center" => [ coord(r + dr), coord(c + dc) ],
          "width" => 0.25, "height" => 0.25,
          "text" => glyphs[edge], "fontSize" => 14, "color" => chevron,
          "textStroke" => WHITE
        })
      end
    end

    # ── connectors ───────────────────────────────────────────────────────────

    def build_connectors
      PuzzleDefinition::JsonKeys::CONNECTOR_TYPES.each do |type|
        entries_for(type).each { |dot| build_connector(type, dot) }
      end
    end

    def build_connector(type, dot)
      cells = Array(dot["cells"])
      return if cells.empty?

      case type
      when "quadruples"
        # The shared corner of the 2x2 the cells span: an integer gridline
        # intersection (the max row/col over the cell coords).
        coords = cells.map { |k| rc(k) }
        corner = [ coords.map(&:first).max, coords.map(&:last).max ]
        values = dot["values"].is_a?(Array) ? dot["values"] : []
        push("overlays", {
          "center" => corner, "width" => QUAD_DIAMETER, "height" => QUAD_DIAMETER, "rounded" => true,
          "backgroundColor" => dot["fillColor"] || WHITE,
          "borderColor" => dot["outlineColor"] || BLACK, "borderSize" => 1.5,
          "text" => values.join(""), "fontSize" => 10,
          "color" => dot["textColor"] || dot["color"] || BLACK
        })
      when "difference_dots", "ratio_dots"
        difference = type == "difference_dots"
        push("overlays", {
          "center" => edge_midpoint(cells[0], cells[1]),
          "width" => DOT_DIAMETER, "height" => DOT_DIAMETER, "rounded" => true,
          "backgroundColor" => dot["fillColor"] || dot["color"] || (difference ? WHITE : BLACK),
          "borderColor" => dot["outlineColor"] || BLACK, "borderSize" => 1.5,
          "text" => dot["value"].nil? ? "" : dot["value"].to_s, "fontSize" => 11.2,
          "color" => dot["textColor"] || (difference ? BLACK : WHITE)
        })
      when "inequality"
        return unless %w[< >].include?(dot["value"])

        # Stacked cells rotate the sign to point up/down.
        stacked = parse_key(cells[0])[0] != parse_key(cells[1])[0]
        glyph = stacked ? (dot["value"] == "<" ? "∧" : "∨") : dot["value"]
        push("overlays", {
          "center" => edge_midpoint(cells[0], cells[1]),
          "width" => 0.3, "height" => 0.3,
          "text" => glyph, "fontSize" => CONNECTOR_GLYPH_SIZE,
          "color" => dot["color"] || BLACK, "textStroke" => WHITE
        })
      when "xv"
        unless %w[X V].include?(dot["value"])
          @warnings << "An XV marker with no X/V letter was dropped."
          return
        end
        push("overlays", {
          "center" => edge_midpoint(cells[0], cells[1]),
          "width" => 0.3, "height" => 0.3,
          "text" => dot["value"], "fontSize" => CONNECTOR_GLYPH_SIZE,
          "color" => dot["color"] || BLACK, "textStroke" => WHITE
        })
      end
    end

    # ── outer clues ──────────────────────────────────────────────────────────

    def build_outer_clues
      PuzzleDefinition::JsonKeys::OUTER_CLUE_TYPES.each do |type|
        entries_for(type).each { |clue| build_outer_clue(type, clue) }
      end
    end

    # Outer clues are text overlays at the ring cell's center — outside the
    # grid proper (SudokuPad auto-expands its margins; browser-verified).
    def build_outer_clue(type, clue)
      pos = parse_key(clue["cell"], strict: false)
      return unless pos

      value = clue["value"].nil? ? "" : clue["value"].to_s
      color = clue["textColor"] || clue["color"] || BLACK
      if type == "little_killers"
        dir = LITTLE_KILLER_DIR[clue["direction"]]
        unless dir
          @warnings << "A little killer with no direction was dropped."
          return
        end
        push_outer_text(clue["cell"], value, OUTER_FONT_SMALL, color) if present?(value)
        build_little_killer_arrow(clue["cell"], dir, clue["arrowColor"] || clue["color"])
      elsif type == "rossini"
        unless %w[increasing decreasing].include?(clue["direction"])
          @warnings << "A rossini clue with no direction was dropped."
          return
        end
        push_outer_text(clue["cell"], rossini_glyph(pos, clue["direction"]), OUTER_FONT_SMALL, color)
      elsif present?(value)
        size = OUTER_SMALL_TYPES.include?(type) ? OUTER_FONT_SMALL : OUTER_FONT_LARGE
        push_outer_text(clue["cell"], value, size, color)
      end
    end

    def push_outer_text(cell_key, text, font_size, color)
      push("overlays", {
        "center" => center(cell_key), "width" => 0.8, "height" => 0.8,
        "text" => text, "fontSize" => font_size, "color" => color
      })
    end

    # The little diagonal arrow between the clue number and the grid corner it
    # points at (OuterCluesLayer.vue draws a 14px shaft at 1.75px stroke).
    def build_little_killer_arrow(cell_key, dir, color)
      r, c = center(cell_key)
      from = [ coord(r + dir[0] * 0.28), coord(c + dir[1] * 0.28) ]
      to = [ coord(r + dir[0] * 0.5), coord(c + dir[1] * 0.5) ]
      push("arrows", {
        "wayPoints" => [ from, to ], "color" => color || BLACK,
        "thickness" => 1.75, "headLength" => 0.12
      })
    end

    # Arrow glyph for a rossini clue: along its row/column, pointing away from
    # the clue's edge for "increasing" and at it for "decreasing". pos is the
    # document ring cell (row/col 0 or size + 1).
    def rossini_glyph(pos, direction)
      increasing = direction == "increasing"
      return increasing ? "→" : "←" if pos[1].zero?
      return increasing ? "←" : "→" if pos[1] > @cols
      return increasing ? "↓" : "↑" if pos[0].zero?
      increasing ? "↑" : "↓"
    end

    # ── instance constraints ─────────────────────────────────────────────────

    def build_constraint_instances
      PuzzleDefinition::JsonKeys::TYPE_TO_JSON_KEY.each do |type, key|
        next unless PuzzleDefinition::JsonKeys.category(type) == :instance

        Array(constraints[key]).each { |entry| build_instance(type, entry) }
      end
    end

    def build_instance(type, entry)
      case type
      when "thermometer" then build_thermo(entry, hollow: false)
      when "slow_thermometer" then build_thermo(entry, hollow: true)
      when "arrow" then build_arrow(entry)
      when "average_arrow" then build_arrow(entry, average: true)
      when "killer_cage"
        push("cages", {
          "cells" => sorted_cells(entry["cells"]),
          "value" => entry["sum"].nil? ? "" : entry["sum"].to_s,
          "unique" => true
        }.merge(entry["cageColor"] || entry["color"] ? { "outlineC" => entry["cageColor"] || entry["color"] } : {}))
      when "extra_regions"
        push("cages", { "cells" => sorted_cells(entry["cells"]), "unique" => true, "outlineC" => TRANSPARENT })
        fill = entry["color"] || EXTRA_REGION_FILL
        Array(entry["cells"]).each do |cell|
          push("underlays", { "center" => center(cell), "width" => 1, "height" => 1, "backgroundColor" => fill })
        end
      when "house"
        # Hidden houses: a fully invisible unique cage conflict-checks without
        # drawing anything (browser-verified).
        push("cages", { "cells" => sorted_cells(entry["cells"]), "unique" => true, "outlineC" => TRANSPARENT })
      when "clone"
        build_clone(entry)
      when *CONSTRAINT_LINE_COLOR.keys
        color = entry["color"] || CONSTRAINT_LINE_COLOR[type]
        push("lines", {
          "wayPoints" => Array(entry["cells"]).map { |k| center(k) },
          "color" => color, "thickness" => CONSTRAINT_LINE_WIDTH
        })
      when "between_lines" then build_between_or_lockout(entry, diamond: false)
      when "lockout_lines" then build_between_or_lockout(entry, diamond: true)
      end
    end

    # Thermometers: one line per root-to-leaf path plus a bulb circle. Regular
    # thermos are filled; slow thermos render hollow in Puzler, approximated
    # here with a hollow bulb (SCL has no hollow line primitive).
    def build_thermo(entry, hollow:)
      line_color = entry["lineColor"] || entry["color"] || THERMO_COLOR
      bulb_color = entry["bulbColor"] || entry["color"] || THERMO_COLOR
      thermo_paths(entry).each do |path|
        push("lines", {
          "wayPoints" => path.map { |k| center(k) },
          "color" => line_color, "thickness" => THERMO_STROKE_WIDTH
        })
      end
      diameter = coord(THERMO_BULB_RADIUS * 2 / CELL_PX.to_f)
      bulb = { "center" => center(entry["bulb"]), "width" => diameter, "height" => diameter, "rounded" => true }
      if hollow
        bulb["backgroundColor"] = WHITE
        bulb["borderColor"] = bulb_color
        bulb["borderSize"] = 3
      else
        bulb["backgroundColor"] = bulb_color
      end
      push("underlays", bulb)
    end

    # Arrows: a native SCL arrow per path (head at the last waypoint), started
    # at the bulb's rim, plus a pill overlay spanning the bulb cells. Average
    # arrows add an inner ring overlay inset inside the (single-cell) bulb.
    def build_arrow(entry, average: false)
      color = entry["arrowColor"] || entry["color"] || ARROW_COLOR
      bulb_cells = Array(entry["bulbCells"])
      Array(entry["arrows"]).each do |path|
        points = Array(path).map { |k| center(k) }
        next if points.length < 2

        points[0] = inset_toward(points[0], points[1], ARROW_BULB_RADIUS / CELL_PX.to_f)
        push("arrows", {
          "wayPoints" => points, "color" => color,
          "thickness" => ARROW_STROKE_WIDTH, "headLength" => coord(ARROW_HEAD_LENGTH / CELL_PX.to_f)
        })
      end
      return if bulb_cells.empty?

      centers = bulb_cells.map { |k| center(k) }
      row_range = centers.map(&:first).minmax
      col_range = centers.map(&:last).minmax
      diameter = ARROW_BULB_RADIUS * 2 / CELL_PX.to_f
      bulb_center = [ coord((row_range[0] + row_range[1]) / 2.0), coord((col_range[0] + col_range[1]) / 2.0) ]
      border_color = entry["bulbStrokeColor"] || entry["color"] || ARROW_COLOR
      push("overlays", {
        "center" => bulb_center,
        "width" => coord(col_range[1] - col_range[0] + diameter),
        "height" => coord(row_range[1] - row_range[0] + diameter),
        "rounded" => true,
        "backgroundColor" => entry["bulbFillColor"] || "none",
        "borderColor" => border_color,
        "borderSize" => ARROW_STROKE_WIDTH
      })
      return unless average

      inner = (ARROW_BULB_RADIUS - AVERAGE_ARROW_BULB_INSET) * 2 / CELL_PX.to_f
      push("overlays", {
        "center" => bulb_center,
        "width" => coord(col_range[1] - col_range[0] + inner),
        "height" => coord(row_range[1] - row_range[0] + inner),
        "rounded" => true,
        "backgroundColor" => "none",
        "borderColor" => border_color,
        "borderSize" => ARROW_STROKE_WIDTH
      })
    end

    def build_between_or_lockout(entry, diamond:)
      cells = Array(entry["cells"])
      return if cells.empty?

      line_color = entry["lineColor"] || entry["color"] || BETWEEN_LINE_COLOR
      push("lines", {
        "wayPoints" => cells.map { |k| center(k) },
        "color" => line_color, "thickness" => BETWEEN_LINE_WIDTH
      })
      end_stroke = diamond ? LOCKOUT_DIAMOND_STROKE : BETWEEN_LINE_COLOR
      # A diamond is a square rotated 45 degrees whose half-diagonal matches
      # the between-line end circle radius.
      size = diamond ? BETWEEN_END_RADIUS * 2 / Math.sqrt(2) : BETWEEN_END_RADIUS * 2
      size = coord(size / CELL_PX.to_f)
      [ cells.first, cells.last ].uniq.each do |cell|
        shape = {
          "center" => center(cell), "width" => size, "height" => size,
          "backgroundColor" => entry["bulbFillColor"] || WHITE,
          "borderColor" => entry["bulbOutlineColor"] || end_stroke,
          "borderSize" => BETWEEN_LINE_WIDTH
        }
        diamond ? shape["angle"] = 45 : shape["rounded"] = true
        push("overlays", shape)
      end
    end

    def build_clone(entry)
      fill = entry["color"] || CLONE_FILL
      cells = Array(entry["cells"])
      groups = [ cells ] + Array(entry["copies"]).map do |copy|
        cells.map do |cell|
          row, col = parse_key(cell)
          "r#{row + copy['dRow']}c#{col + copy['dCol']}"
        end
      end
      groups.each do |group|
        group.each do |cell|
          push("underlays", { "center" => center(cell), "width" => 1, "height" => 1, "backgroundColor" => fill })
        end
      end
      @unchecked_rules << "clones"
    end

    # ── cosmetics ────────────────────────────────────────────────────────────

    def build_cosmetic_instances
      Array(cosmetics["lines"]).each do |line|
        style = find_preset("linePresets", line["preset"])&.dig("style")
        push("lines", {
          "wayPoints" => Array(line["cells"]).map { |k| center(k) },
          "color" => blend_opacity(style&.dig("color") || "#777777", style&.dig("opacity")),
          "thickness" => style&.dig("strokeWidth") || 8
        })
      end
      # Cosmetic borders run along the shared gridline of each edge pair —
      # SCL lines between the edge's two endpoint intersections.
      Array(cosmetics["borders"]).each do |border|
        style = find_preset("borderPresets", border["preset"])&.dig("style")
        color = blend_opacity(style&.dig("color") || "#232B3D", style&.dig("opacity"))
        thickness = style&.dig("strokeWidth") || 2.5
        Array(border["edges"]).each do |edge|
          a, b = Array(edge)
          next if a.nil? || b.nil?

          push("lines", { "wayPoints" => edge_segment(a, b), "color" => color, "thickness" => thickness })
        end
      end
      Array(cosmetics["shapes"]).each { |shape| build_shape(shape) }
      Array(cosmetics["texts"]).each { |text| build_text(text) }
      Array(cosmetics["cages"]).each do |cage|
        style = find_preset("cagePresets", cage["preset"])&.dig("style")
        push("cages", {
          "cells" => sorted_cells(cage["cells"]),
          "value" => cage["sum"].nil? ? "" : cage["sum"].to_s,
          "outlineC" => blend_opacity(style&.dig("cageColor") || "#777777", style&.dig("cageOpacity")),
          "fontC" => blend_opacity(style&.dig("textColor") || "#777777", style&.dig("textOpacity"))
        })
      end
    end

    def build_shape(entry)
      style = find_preset("shapePresets", entry["preset"])&.dig("style")
      is_diamond = style&.dig("shapeType") == "diamond"
      is_circle = style&.dig("shapeType") == "circle"
      width = style&.dig("width") || style&.dig("size") || 0.5
      height = style&.dig("height") || style&.dig("size") || 0.5
      fill = blend_opacity(style&.dig("fillColor") || "none", style&.dig("fillOpacity"))
      shape = {
        "center" => free_pos(entry["pos"]),
        "width" => coord(width), "height" => coord(height),
        "backgroundColor" => fill == "none" ? "none" : fill,
        "borderColor" => blend_opacity(style&.dig("strokeColor") || "#333333", style&.dig("strokeOpacity")),
        "borderSize" => 2
      }
      shape["rounded"] = true if is_circle
      if present?(entry["content"])
        shape["text"] = entry["content"]
        shape["fontSize"] = style&.dig("textSize") || 20
        shape["color"] = blend_opacity(style&.dig("textColor") || "#333333", style&.dig("textOpacity"))
      end
      angle = (((is_diamond ? 45 : 0) + (entry["rotation"] || 0)) % 360 + 360) % 360
      shape["angle"] = angle unless angle.zero?
      push("overlays", shape)
    end

    def build_text(entry)
      style = find_preset("textPresets", entry["preset"])&.dig("style")
      text = {
        "center" => free_pos(entry["pos"]),
        "width" => 1, "height" => 1,
        "text" => entry["content"] || "",
        "fontSize" => style&.dig("fontSize") || 20,
        "color" => blend_opacity(style&.dig("color") || "#333333", style&.dig("opacity"))
      }
      angle = ((entry["rotation"] || 0) % 360 + 360) % 360
      text["angle"] = angle unless angle.zero?
      push("overlays", text)
    end

    # ── coordinate helpers (see class comment for the convention) ────────────

    def push(section, entry)
      (@scl[section] ||= []) << entry
    end

    def invalid_key_error
      Error
    end

    # Doc key (1-indexed) -> integer SCL cell coords [r, c] (0-indexed).
    def rc(key)
      row, col = parse_key(key)
      [ row - 1, col - 1 ]
    end

    # Cage/region cell lists sorted row-major so SudokuPad places the value
    # label in the top-left cell, like Puzler does.
    def sorted_cells(cells)
      Array(cells).map { |k| rc(k) }.sort
    end

    # Doc key -> the cell's center point [r - 0.5, c - 0.5].
    def center(key)
      row, col = parse_key(key)
      [ coord(row - 0.5), coord(col - 0.5) ]
    end

    # Midpoint of two cell centers (kropki/XV/inequality edge positions).
    def edge_midpoint(a, b)
      ra, ca = center(a)
      rb, cb = center(b)
      [ coord((ra + rb) / 2.0), coord((ca + cb) / 2.0) ]
    end

    # The shared gridline segment between two adjacent cells, as intersection
    # coords (cosmetic borders).
    def edge_segment(a, b)
      ra, ca = parse_key(a)
      rb, cb = parse_key(b)
      if ra == rb
        col = [ ca, cb ].max - 1
        [ [ ra - 1, col ], [ ra, col ] ]
      else
        row = [ ra, rb ].max - 1
        [ [ row, ca - 1 ], [ row, ca ] ]
      end
    end

    # Point a moved toward point b by `distance` (cell units) — arrow shafts
    # start at the bulb's rim, not its center.
    def inset_toward(a, b, distance)
      dr = b[0] - a[0]
      dc = b[1] - a[1]
      length = Math.sqrt(dr * dr + dc * dc)
      return a if length.zero? || length <= distance

      [ coord(a[0] + dr / length * distance), coord(a[1] + dc / length * distance) ]
    end

    # Free positions are in document cell units (r1c1's centre = x 1.5, y 1.5);
    # SCL wants the same point one unit up/left, as [row, col].
    def free_pos(pos)
      pos = pos.is_a?(Hash) ? pos : { "x" => 1.5, "y" => 1.5 }
      [ coord(pos["y"] - 1), coord(pos["x"] - 1) ]
    end

    # Whole numbers as Integers keeps payloads compact and JSON stable.
    def coord(num)
      num == num.to_i ? num.to_i : num.round(4)
    end
  end
end
