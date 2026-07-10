module Fpuzzles
  class Error < StandardError; end
  class UnsupportedGrid < Error; end

  # Builds the f-puzzles object (and fidelity warnings) from a Puzler `definition`
  # (the stored SerializedPuzzle jsonb) plus an optional solution. Reads puzzle
  # format v4 — every definition is normalized through
  # PuzzleDefinition::Migrator.v3_to_v4 at entry, so pre-v4 stored documents and
  # saved export files keep working permanently.
  #
  # v4 documents are 1-indexed like f-puzzles itself, so document cell keys map
  # directly to `R{row}C{col}` (the old +1 shift lives only in the migrator).
  # The separate `solution` argument is NOT part of the document and stays
  # 0-indexed (internal board-snapshot keys).
  #
  # Output stays equivalent to the pre-v4 encoder (verified against every
  # stored definition by the since-removed puzzle_format:verify parity harness
  # before the v4 backfill ran; see git history).
  #
  # EXPORT IS THEME-AGNOSTIC: styling comes only from the f-puzzles colour maps
  # below and the author's cosmetic presets — never a user theme.
  class Encoder
    Result = Struct.new(:data, :warnings)

    TRANSPARENT = "#00000000".freeze
    INDEX_CELL_COLOR = { "row" => "#FFD9D9", "col" => "#CBF1D5", "both" => "#FFF8C4" }.freeze
    INDEXER_FIELD = { "row_index_cells" => "rowindexer", "col_index_cells" => "columnindexer" }.freeze
    SINGLE_FIELD = { "odd_cells" => "odd", "even_cells" => "even", "minimums" => "minimum", "maximums" => "maximum" }.freeze
    OUTER_FIELD = { "x_sums" => "xsum", "sandwich_sums" => "sandwichsum", "skyscrapers" => "skyscraper" }.freeze
    OUTER_UNRENDERED = %w[x_sums skyscrapers].freeze
    # Outer clues with no f-puzzles field at all: exported as cosmetic text only.
    OUTER_TEXT_ONLY = %w[numbered_rooms battlefield next_to_nine].freeze
    LITTLE_KILLER_DIR = { "up-left" => "UL", "up-right" => "UR", "down-left" => "DL", "down-right" => "DR" }.freeze
    CONSTRAINT_LINE_FIELD = {
      "renban" => "renban", "german_whispers" => "whispers", "palindrome" => "palindrome",
      "region_sum" => "regionsumline", "between_lines" => "betweenline", "lockout_lines" => "lockout"
    }.freeze
    UNRENDERED_LINE_COSMETIC = {
      "renban" => { "outlineC" => "#F067F0", "width" => 0.4 },
      "german_whispers" => { "outlineC" => "#67F067", "width" => 0.3 },
      "region_sum" => { "outlineC" => "#2ECBFF", "width" => 0.25 }
    }.freeze
    # Lines with no f-puzzles constraint field at all: exported as a cosmetic line
    # only, in the constraint's classic colour.
    COSMETIC_ONLY_LINE = {
      "dutch_whispers" => { "outlineC" => "#FF9A00", "width" => 0.3 },
      "entropic_lines" => { "outlineC" => "#FA9678", "width" => 0.3 },
      "modular_lines" => { "outlineC" => "#00B5AD", "width" => 0.3 },
      "nabner_lines" => { "outlineC" => "#F0C300", "width" => 0.3 },
      "zipper_lines" => { "outlineC" => "#AC8AFF", "width" => 0.3 }
    }.freeze
    THERMO_COLOR = "#aaaaaa".freeze
    THERMO_STROKE_WIDTH = 12
    THERMO_BULB_RADIUS = 18
    # Every per-instance setter color field a v4 document can carry
    # (INSTANCE_COLOR_FIELDS in the frontend registry). Fields a build site
    # cannot map onto an f-puzzles color feed one aggregated fidelity warning
    # instead of vanishing silently.
    INSTANCE_COLOR_FIELDS = %w[
      color lineColor bulbFillColor bulbOutlineColor bulbStrokeColor bulbColor arrowColor
      cageColor textColor fillColor outlineColor backgroundColor chevronColor
    ].freeze
    HEX_COLOR = /\A#(\h{6})(\h{2})?\z/

    def self.call(definition:, solution: nil, include_solution: true, fallback_author: nil)
      new(definition, solution, include_solution, fallback_author).call
    end

    def initialize(definition, solution, include_solution, fallback_author)
      @raw = (definition || {}).deep_stringify_keys
      @solution = solution
      @include_solution = include_solution
      @fallback_author = fallback_author
      @warnings = []
      @dropped_color_keys = []
      @fp = {}
    end

    def call
      grid = @raw["grid"] || {}
      @size = grid["rows"]
      unless @size.is_a?(Integer) && @size.positive? && @size == grid["cols"]
        raise UnsupportedGrid, "SudokuPad export needs a square grid; this puzzle is not square."
      end

      @def = PuzzleDefinition::Migrator.v3_to_v4(@raw)

      # f-puzzles has no way to express a grid without sudoku rules, and
      # SudokuPad always enforces them. Key presence carries the rule: a
      # missing sudokuRules group means the puzzle has no sudoku rules (the
      # migrator stamps the group onto every pre-v4 document, so old puzzles
      # pass).
      sudoku_rules = @def.dig("globals", "sudokuRules")
      if sudoku_rules.nil? || sudoku_rules["enabled"] == false
        raise UnsupportedGrid, "SudokuPad always enforces sudoku rules; this puzzle has them disabled."
      end

      meta = @def["meta"] || {}
      @fp["size"] = @size
      @fp["title"] = meta["name"] if present?(meta["name"])
      author = present?(meta["author"]) ? meta["author"] : @fallback_author
      @fp["author"] = author if present?(author)
      @fp["ruleset"] = meta["rules"] if present?(meta["rules"])

      # Fog puzzles need the embedded solution to clear fog in SudokuPad, so
      # it is always included regardless of the author's export preference.
      if fog_enabled?
        @include_solution = true
        if @solution.blank?
          @warnings << "Fog needs an embedded solution to work in SudokuPad; set a solution before exporting."
        end
      end

      build_grid(@def["grid"] || {})
      build_solution
      build_globals
      build_fog
      build_single_cell_marks
      build_connectors
      build_outer_clues
      build_constraint_instances
      build_cosmetic_instances

      unless @dropped_color_keys.empty?
        @warnings << "Per-instance colors on #{@dropped_color_keys.uniq.join(', ')} have no SudokuPad equivalent and were dropped."
      end
      Result.new(@fp, @warnings)
    end

    private

    def constraints = @def["constraints"] || {}
    def cosmetics = @def["cosmetics"] || {}
    def globals = @def["globals"] || {}

    def entries_for(type)
      Array(constraints[PuzzleDefinition::JsonKeys::TYPE_TO_JSON_KEY.fetch(type)])
    end

    def single_cell_marks(type)
      constraints[PuzzleDefinition::JsonKeys::TYPE_TO_JSON_KEY.fetch(type)]
    end

    # v4 single-cell entries are the plain cell string, or { cell, ...colors }
    # when the mark carries per-instance setter colors. Normalized to
    # [cell_key, colors_hash] pairs so every consumer reads one shape.
    def single_cell_entries(type)
      Array(single_cell_marks(type)).filter_map do |item|
        if item.is_a?(Hash)
          item["cell"] ? [ item["cell"], item ] : nil
        else
          [ item, {} ]
        end
      end
    end

    # Records instance color fields this build site could not map onto an
    # f-puzzles color (everything outside `used`), for the aggregated warning.
    def note_unexportable_colors(type, entry, used = [])
      return unless entry.is_a?(Hash)
      return unless (INSTANCE_COLOR_FIELDS - used).any? { |field| present?(entry[field]) }

      @dropped_color_keys << PuzzleDefinition::JsonKeys::TYPE_TO_JSON_KEY.fetch(type, type)
    end

    # Bakes a 0-1 opacity into a hex color: 6-digit stays 6-digit at full
    # opacity, otherwise the alpha byte is appended (SudokuPad renders 8-digit
    # hex; TRANSPARENT relies on that already). An 8-digit input's own alpha
    # multiplies with the opacity. Non-hex strings (documents are lenient)
    # pass through untouched, dropping the opacity.
    def blend_opacity(color, opacity)
      return color unless opacity.is_a?(Numeric) && opacity < 1

      m = HEX_COLOR.match(color.to_s)
      return color unless m

      alpha = (m[2] ? m[2].to_i(16) / 255.0 : 1.0) * opacity.clamp(0, 1)
      byte = (alpha * 255).round
      byte >= 255 ? "##{m[1]}" : format("#%s%02x", m[1], byte)
    end

    def build_grid(grid)
      color_by_id = (cosmetics["cellColorPresets"] || []).to_h { |p| [ p["id"], blend_opacity(p["color"], p["opacity"]) ] }

      # `grid.regions` is region-first (label -> complete 1-indexed cell list);
      # a cell listed nowhere is regionless. Region indices follow sorted
      # labels, matching the frontend converter.
      label_by_cell = nil
      label_to_region = nil
      regions = grid["regions"]
      if regions.is_a?(Hash) && !regions.empty?
        label_to_region = regions.keys.sort.each_with_index.to_h
        label_by_cell = {}
        regions.each { |label, cells| Array(cells).each { |cell| label_by_cell[cell] = label } }
      end

      row_index = single_cell_entries("row_index_cells").to_h
      col_index = single_cell_entries("col_index_cells").to_h
      { "row_index_cells" => row_index, "col_index_cells" => col_index }.each do |type, pairs|
        pairs.each_value { |colors| note_unexportable_colors(type, colors, %w[color]) }
      end
      cell_colors = cosmetics["cellColors"] || {}
      givens = @def["givenDigits"] || {}

      has_null_region = false
      cells = Array.new(@size) do |r|
        Array.new(@size) do |c|
          key = "r#{r + 1}c#{c + 1}"
          cell = {}
          given = givens[key]
          unless given.nil?
            cell["value"] = given
            cell["given"] = true
          end
          if label_to_region
            label = label_by_cell[key]
            if label
              cell["region"] = label_to_region[label]
            else
              has_null_region = true
            end
          end
          color_id = cell_colors[key]
          if color_id && color_by_id.key?(color_id)
            cell["c"] = color_by_id[color_id]
          else
            is_row = row_index.key?(key)
            is_col = col_index.key?(key)
            # A per-instance setter color on either index mark beats the tint.
            setter = (is_row && row_index[key]["color"]) || (is_col && col_index[key]["color"]) || nil
            cell["c"] = setter || INDEX_CELL_COLOR["both"] if is_row && is_col
            cell["c"] = setter || INDEX_CELL_COLOR["row"] if is_row && !is_col
            cell["c"] = setter || INDEX_CELL_COLOR["col"] if is_col && !is_row
          end
          cell
        end
      end
      @fp["grid"] = cells
      @warnings << "Some cells belong to no region; SudokuPad may assign them a default box." if has_null_region
    end

    # The solution argument comes from the version's own column (internal
    # board-snapshot keys, still 0-indexed), not from the v4 document.
    def build_solution
      return unless @include_solution && @solution.is_a?(Hash) && !@solution.empty?

      sol = Array.new(@size * @size, "")
      @solution.each do |key, digit|
        row, col = parse_key(key)
        sol[row * @size + col] = digit.to_s if row < @size && col < @size
      end
      @fp["solution"] = sol
    end

    def build_globals
      diagonals = global_group("diagonals")
      chess = global_group("chess")
      anti_kropki = global_group("antiKropki")
      anti_xv = global_group("antiXv")
      disjoint = global_group("disjointSets")

      negative = []
      @fp["diagonal+"] = true if diagonals["positive"] == true
      @fp["diagonal-"] = true if diagonals["negative"] == true
      @fp["antiking"] = true if chess["king"] == true
      @fp["antiknight"] = true if chess["knight"] == true
      @fp["nonconsecutive"] = true if anti_kropki["white"] == true
      @fp["disjointgroups"] = true if disjoint["enabled"] == true
      negative << "ratio" if anti_kropki["black"] == true
      negative << "xv" if anti_xv["x"] == true || anti_xv["v"] == true
      { "positive" => "antiPositive", "negative" => "antiNegative" }.each do |kind, toggle|
        next unless diagonals[toggle] == true

        push("line", {
          "lines" => [ diagonal_cells(kind) ],
          "outlineC" => "#f06292", "width" => 0.05, "isNewConstraint" => true
        })
      end

      custom_globals.each do |cg|
        if cg[:type] == "anti_diff" && cg[:value] == 1 then negative << "difference"
        elsif cg[:type] == "anti_ratio" && cg[:value] == 2 then negative << "ratio"
        else @warnings << "Custom \"#{cg[:type]}\" (value #{cg[:value]}) has no SudokuPad equivalent and was dropped."
        end
      end
      @fp["negative"] = negative.uniq unless negative.empty?
    end

    def global_group(key)
      entry = globals[key]
      entry.is_a?(Hash) ? entry : {}
    end

    def fog_enabled?
      global_group("fog")["enabled"] == true
    end

    # SudokuPad fog keys: `foglight` lights single cells (exactly Puzler's
    # lights); `fogofwar` cells would clear a whole 3x3 "lamp" neighborhood,
    # so it is emitted empty and only to help fog activation.
    def build_fog
      return unless fog_enabled?

      lights = single_cell_entries("fog_lights")
      @fp["foglight"] = lights.map { |key, _| fp_cell(key) }
      @fp["fogofwar"] = []
      lights.each { |_, colors| note_unexportable_colors("fog_lights", colors) }
    end

    # Custom global values in canonical group/field order (the migrator sorts
    # each field's values ascending).
    def custom_globals
      PuzzleDefinition::JsonKeys::GLOBAL_GROUPS.flat_map do |group|
        entry = global_group(group[:key])
        group[:custom_values].flat_map do |field, custom_type|
          Array(entry[field]).map { |value| { type: custom_type, value: value } }
        end
      end
    end

    def build_single_cell_marks
      SINGLE_FIELD.each do |type, field|
        single_cell_entries(type).each do |key, colors|
          push(field, { "cell" => fp_cell(key) })
          # The native odd/even/minimum/maximum fields carry no color.
          note_unexportable_colors(type, colors)
        end
      end
      INDEXER_FIELD.each do |type, field|
        pairs = single_cell_entries(type)
        push(field, { "cells" => pairs.map { |key, _| fp_cell(key) } }) unless pairs.empty?
      end
      # Counting circles have no f-puzzles field: cosmetic outline rings. Setter
      # colors apply per the frontend rule: generic `color` reaches the fill
      # only, the outline changes via outlineColor.
      single_cell_entries("counting_circles").each do |key, colors|
        push("circle", {
          "cells" => [ fp_cell(key) ],
          "baseC" => fp_color(colors["fillColor"] || colors["color"] || "none"),
          "outlineC" => colors["outlineColor"] || "#666666",
          "width" => 0.8, "height" => 0.8
        })
        note_unexportable_colors("counting_circles", colors, %w[color fillColor outlineColor])
      end
    end

    def build_connectors
      PuzzleDefinition::JsonKeys::CONNECTOR_TYPES.each do |type|
        entries_for(type).each { |dot| build_connector(type, dot) }
      end
    end

    def build_connector(type, dot)
      cells = Array(dot["cells"])
      return if cells.empty?

      pair = cells.map { |k| fp_cell(k) }
      case type
      when "quadruples"
        push("quadruple", { "cells" => pair, "values" => dot["values"].is_a?(Array) ? dot["values"] : [] })
        note_unexportable_colors(type, dot)
      when "difference_dots"
        push("difference", { "cells" => pair, "value" => dot["value"].nil? ? "" : dot["value"].to_s })
        note_unexportable_colors(type, dot)
      when "ratio_dots"
        push("ratio", { "cells" => pair, "value" => dot["value"].nil? ? "" : dot["value"].to_s })
        note_unexportable_colors(type, dot)
      when "inequality"
        if %w[< >].include?(dot["value"])
          # No f-puzzles equivalent: a cosmetic glyph centred on the border.
          # Stacked cells rotate the sign to point up/down.
          stacked = parse_key(cells[0])[0] != parse_key(cells[1])[0]
          glyph = stacked ? (dot["value"] == "<" ? "∧" : "∨") : dot["value"]
          push("text", { "cells" => pair, "value" => glyph, "fontC" => dot["color"] || "#000000", "size" => 0.3 })
          note_unexportable_colors(type, dot, %w[color])
        end
      when "xv"
        if %w[X V].include?(dot["value"]) then push("xv", { "cells" => pair, "value" => dot["value"] })
        else @warnings << "An XV marker with no X/V letter was dropped."
        end
        note_unexportable_colors(type, dot)
      end
    end

    def build_outer_clues
      PuzzleDefinition::JsonKeys::OUTER_CLUE_TYPES.each do |type|
        entries_for(type).each { |clue| build_outer_clue(type, clue) }
      end
    end

    def build_outer_clue(type, clue)
      pos = parse_key(clue["cell"], strict: false)
      return unless pos

      cell = "R#{pos[0]}C#{pos[1]}"
      value = clue["value"].nil? ? "" : clue["value"].to_s
      if type == "little_killers"
        dir = clue["direction"] ? LITTLE_KILLER_DIR[clue["direction"]] : nil
        if dir then push("littlekillersum", { "cell" => cell, "direction" => dir, "value" => value })
        else @warnings << "A little killer with no direction was dropped."
        end
        note_unexportable_colors(type, clue)
      elsif OUTER_FIELD[type]
        push(OUTER_FIELD[type], { "cell" => cell, "value" => value })
        if OUTER_UNRENDERED.include?(type) && present?(value)
          push("text", { "cells" => [ cell ], "value" => value, "fontC" => clue["color"] || "#000000", "size" => 0.7 })
          note_unexportable_colors(type, clue, %w[color])
        else
          note_unexportable_colors(type, clue)
        end
      elsif OUTER_TEXT_ONLY.include?(type) && present?(value)
        push("text", { "cells" => [ cell ], "value" => value, "fontC" => clue["color"] || "#000000", "size" => 0.7 })
        note_unexportable_colors(type, clue, %w[color])
      elsif type == "rossini"
        if %w[increasing decreasing].include?(clue["direction"])
          glyph = rossini_glyph(pos, clue["direction"])
          push("text", { "cells" => [ cell ], "value" => glyph, "fontC" => clue["color"] || "#000000", "size" => 0.7 })
          note_unexportable_colors(type, clue, %w[color])
        else
          @warnings << "A rossini clue with no direction was dropped."
        end
      end
    end

    # Arrow glyph for a rossini clue: along its row/column, pointing away from
    # the clue's edge for "increasing" and at it for "decreasing". pos is the
    # document ring cell (row/col 0 or size + 1).
    def rossini_glyph(pos, direction)
      increasing = direction == "increasing"
      return increasing ? "→" : "←" if pos[1].zero?
      return increasing ? "←" : "→" if pos[1] > @size
      return increasing ? "↓" : "↑" if pos[0].zero?
      increasing ? "↑" : "↓"
    end

    # Instance-based constraints, in registry-canonical type order (the order
    # the migrator/serializer emits document keys).
    def build_constraint_instances
      PuzzleDefinition::JsonKeys::TYPE_TO_JSON_KEY.each do |type, key|
        next unless PuzzleDefinition::JsonKeys.category(type) == :instance

        Array(constraints[key]).each { |entry| build_instance(type, entry) }
      end
    end

    def build_instance(type, entry)
      case type
      when "thermometer"
        push("thermometer", { "lines" => thermo_lines(entry) })
        note_unexportable_colors(type, entry)
      when "slow_thermometer"
        # Rendered as cosmetics, so per-instance setter colors apply directly
        # (specific bulbColor/lineColor beat the generic color).
        line_color = entry["lineColor"] || entry["color"] || THERMO_COLOR
        thermo_lines(entry).each do |line|
          push("line", { "lines" => [ line ], "outlineC" => line_color, "width" => THERMO_STROKE_WIDTH / 64.0, "isNewConstraint" => true })
        end
        push("circle", {
          "cells" => [ fp_cell(entry["bulb"]) ], "baseC" => fp_color("none"),
          "outlineC" => entry["bulbColor"] || entry["color"] || THERMO_COLOR,
          "width" => (THERMO_BULB_RADIUS * 2) / 64.0, "height" => (THERMO_BULB_RADIUS * 2) / 64.0
        })
        note_unexportable_colors(type, entry, %w[color lineColor bulbColor])
      when "arrow"
        push("arrow", {
          "lines" => Array(entry["arrows"]).map { |cells| Array(cells).map { |k| fp_cell(k) } },
          "cells" => Array(entry["bulbCells"]).map { |k| fp_cell(k) }
        })
        note_unexportable_colors(type, entry)
      when "killer_cage"
        push("killercage", { "cells" => Array(entry["cells"]).map { |k| fp_cell(k) }, "value" => entry["sum"].nil? ? "" : entry["sum"].to_s })
        note_unexportable_colors(type, entry)
      when "extra_regions"
        push("extraregion", { "cells" => Array(entry["cells"]).map { |k| fp_cell(k) } })
        note_unexportable_colors(type, entry)
      when "clone"
        build_clone(entry)
        note_unexportable_colors(type, entry)
      when *COSMETIC_ONLY_LINE.keys
        style = COSMETIC_ONLY_LINE[type]
        style = style.merge("outlineC" => entry["color"]) if present?(entry["color"])
        push("line", { "lines" => [ Array(entry["cells"]).map { |k| fp_cell(k) } ] }.merge(style).merge("isNewConstraint" => true))
        note_unexportable_colors(type, entry, %w[color])
      else
        field = CONSTRAINT_LINE_FIELD[type]
        return unless field

        line_cells = Array(entry["cells"]).map { |k| fp_cell(k) }
        push(field, { "lines" => [ line_cells ] })
        cosmetic = UNRENDERED_LINE_COSMETIC[type]
        if cosmetic
          cosmetic = cosmetic.merge("outlineC" => entry["color"]) if present?(entry["color"])
          push("line", { "lines" => [ line_cells ] }.merge(cosmetic).merge("isNewConstraint" => true))
          note_unexportable_colors(type, entry, %w[color])
        else
          # Natively rendered lines (palindrome, between, lockout): SudokuPad
          # draws them itself, so setter colors cannot apply.
          note_unexportable_colors(type, entry)
        end
      end
    end

    def build_clone(entry)
      Array(entry["copies"]).each do |copy|
        clone_cells = Array(entry["cells"]).map do |cell|
          row, col = parse_key(cell)
          "R#{row + copy['dRow']}C#{col + copy['dCol']}"
        end
        push("clone", { "cells" => Array(entry["cells"]).map { |k| fp_cell(k) }, "cloneCells" => clone_cells })
      end
    end

    # Cosmetic kinds in canonical order (cell colours are painted in
    # build_grid; presets are looked up by their document slug ids).
    def build_cosmetic_instances
      Array(cosmetics["lines"]).each do |line|
        style = find_preset("linePresets", line["preset"])&.dig("style")
        push("line", {
          "lines" => [ Array(line["cells"]).map { |k| fp_cell(k) } ],
          "outlineC" => blend_opacity(style&.dig("color") || "#777777", style&.dig("opacity")),
          "width" => (style&.dig("strokeWidth") || 8) / 64.0
        })
      end
      # Cosmetic borders have no f-puzzles primitive; a thin rectangle spanning
      # the two cells renders along their shared edge (a two-cell "cells" list
      # centres the shape between them). Vertical neighbours share a horizontal
      # edge (full cell width, stroke-thin height) and vice versa.
      Array(cosmetics["borders"]).each do |border|
        style = find_preset("borderPresets", border["preset"])&.dig("style")
        color = blend_opacity(style&.dig("color") || "#232B3D", style&.dig("opacity"))
        thickness = (style&.dig("strokeWidth") || 2.5) / 64.0
        Array(border["edges"]).each do |edge|
          a, b = Array(edge)
          next if a.nil? || b.nil?
          row_a, = parse_key(a)
          row_b, = parse_key(b)
          horizontal_edge = row_a != row_b
          push("rectangle", {
            "cells" => [ fp_cell(a), fp_cell(b) ],
            "baseC" => fp_color(color),
            "outlineC" => color,
            "fontC" => "#000000",
            "width" => horizontal_edge ? 1 : thickness,
            "height" => horizontal_edge ? thickness : 1,
            "value" => ""
          })
        end
      end
      Array(cosmetics["shapes"]).each { |shape| build_shape(shape) }
      Array(cosmetics["texts"]).each { |text| build_text(text) }
      Array(cosmetics["cages"]).each do |cage|
        style = find_preset("cagePresets", cage["preset"])&.dig("style")
        push("cage", {
          "cells" => Array(cage["cells"]).map { |k| fp_cell(k) }, "value" => cage["sum"].nil? ? "" : cage["sum"].to_s,
          "outlineC" => blend_opacity(style&.dig("cageColor") || "#777777", style&.dig("cageOpacity")),
          "fontC" => blend_opacity(style&.dig("textColor") || "#777777", style&.dig("textOpacity"))
        })
      end
    end

    def build_shape(entry)
      style = find_preset("shapePresets", entry["preset"])&.dig("style")
      is_diamond = style&.dig("shapeType") == "diamond"
      field = style&.dig("shapeType") == "circle" ? "circle" : "rectangle"
      # Hand-edited documents may still carry the pre-dimension `size`; the
      # migrator resolves it, so this fallback is belt-and-braces. Diamonds
      # with width != height export wrong by necessity: a 45-degree-rotated
      # rectangle can't be a rhombus with unequal diagonals, and f-puzzles has
      # no closer primitive.
      width = style&.dig("width") || style&.dig("size") || 0.5
      height = style&.dig("height") || style&.dig("size") || 0.5
      shape = {
        "cells" => [ fp_pos(entry["pos"]) ],
        "baseC" => fp_color(blend_opacity(style&.dig("fillColor") || "none", style&.dig("fillOpacity"))),
        "outlineC" => blend_opacity(style&.dig("strokeColor") || "#333333", style&.dig("strokeOpacity")),
        "fontC" => blend_opacity(style&.dig("textColor") || "#000000", style&.dig("textOpacity")),
        "width" => width, "height" => height,
        "value" => entry["content"] || ""
      }
      angle = (((is_diamond ? 45 : 0) + (entry["rotation"] || 0)) % 360 + 360) % 360
      shape["angle"] = angle unless angle.zero?
      push(field, shape)
    end

    def build_text(entry)
      style = find_preset("textPresets", entry["preset"])&.dig("style")
      text = {
        "cells" => [ fp_pos(entry["pos"]) ],
        "value" => entry["content"] || "",
        "fontC" => blend_opacity(style&.dig("color") || "#333333", style&.dig("opacity")),
        "size" => (style&.dig("fontSize") || 20) / 50.0
      }
      text["angle"] = ((entry["rotation"] % 360) + 360) % 360 if present?(entry["rotation"])
      push("text", text)
    end

    # ── helpers ──────────────────────────────────────────────────────────────
    def push(field, entry)
      (@fp[field] ||= []) << entry
    end

    def find_preset(kind, id)
      (cosmetics[kind] || []).find { |p| p["id"] == id }
    end

    def present?(value)
      !value.nil? && value != ""
    end

    # Document cell keys are 1-indexed; the outer clue ring is r0 / r{size+1}.
    def parse_key(key, strict: true)
      m = key.to_s.match(/\Ar(\d+)c(\d+)\z/)
      unless m
        raise Error, "Invalid cell key: #{key}" if strict

        return nil
      end

      [ m[1].to_i, m[2].to_i ]
    end

    def fp_cell(key)
      row, col = parse_key(key)
      "R#{row}C#{col}"
    end

    def fp_color(color)
      color == "none" ? TRANSPARENT : color
    end

    # Free positions are in document cell units (r1c1's centre = x 1.5, y 1.5);
    # f-puzzles wants the same point 0.5 higher/lefter in each axis.
    def fp_pos(pos)
      pos = pos.is_a?(Hash) ? pos : { "x" => 1.5, "y" => 1.5 }
      "R#{fmt(pos['y'] - 0.5)}C#{fmt(pos['x'] - 0.5)}"
    end

    # Match JS Number→string: whole numbers without a trailing ".0".
    def fmt(num)
      num == num.to_i ? num.to_i.to_s : num.to_s
    end

    def diagonal_cells(kind)
      (1..@size).map do |i|
        row = kind == "positive" ? @size + 1 - i : i
        "R#{row}C#{i}"
      end
    end

    # Document { bulb, lines } -> f-puzzles root-to-leaf lines (the document's
    # lines restart at branch points; f-puzzles repeats the shared prefix).
    def thermo_lines(entry)
      adj = Hash.new { |h, k| h[k] = [] }
      Array(entry["lines"]).each do |line|
        Array(line).each_cons(2) { |from, to| adj[from] << to }
      end
      paths = []
      walk = lambda do |cell, path|
        nexts = adj[cell]
        if nexts.empty?
          paths << path
        else
          nexts.each { |n| walk.call(n, path + [ n ]) }
        end
      end
      walk.call(entry["bulb"], [ entry["bulb"] ])
      paths.map { |p| p.map { |k| fp_cell(k) } }
    end
  end
end
