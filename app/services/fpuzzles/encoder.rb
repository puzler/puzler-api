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

    def self.call(definition:, solution: nil, include_solution: true, fallback_author: nil)
      new(definition, solution, include_solution, fallback_author).call
    end

    def initialize(definition, solution, include_solution, fallback_author)
      @raw = (definition || {}).deep_stringify_keys
      @solution = solution
      @include_solution = include_solution
      @fallback_author = fallback_author
      @warnings = []
      @fp = {}
    end

    def call
      grid = @raw["grid"] || {}
      @size = grid["rows"]
      unless @size.is_a?(Integer) && @size.positive? && @size == grid["cols"]
        raise UnsupportedGrid, "SudokuPad export needs a square grid; this puzzle is not square."
      end

      @def = PuzzleDefinition::Migrator.v3_to_v4(@raw)

      meta = @def["meta"] || {}
      @fp["size"] = @size
      @fp["title"] = meta["name"] if present?(meta["name"])
      author = present?(meta["author"]) ? meta["author"] : @fallback_author
      @fp["author"] = author if present?(author)
      @fp["ruleset"] = meta["rules"] if present?(meta["rules"])

      build_grid(@def["grid"] || {})
      build_solution
      build_globals
      build_single_cell_marks
      build_connectors
      build_outer_clues
      build_constraint_instances
      build_cosmetic_instances

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

    def build_grid(grid)
      color_by_id = (cosmetics["cellColorPresets"] || []).to_h { |p| [ p["id"], p["color"] ] }

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

      row_index = single_cell_marks("row_index_cells") || []
      col_index = single_cell_marks("col_index_cells") || []
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
            is_row = row_index.include?(key)
            is_col = col_index.include?(key)
            cell["c"] = INDEX_CELL_COLOR["both"] if is_row && is_col
            cell["c"] = INDEX_CELL_COLOR["row"] if is_row && !is_col
            cell["c"] = INDEX_CELL_COLOR["col"] if is_col && !is_row
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
        cells = single_cell_marks(type)
        next unless cells

        cells.each { |key| push(field, { "cell" => fp_cell(key) }) }
      end
      INDEXER_FIELD.each do |type, field|
        cells = single_cell_marks(type)
        push(field, { "cells" => cells.map { |k| fp_cell(k) } }) if cells && !cells.empty?
      end
      # Counting circles have no f-puzzles field: cosmetic outline rings.
      (single_cell_marks("counting_circles") || []).each do |key|
        push("circle", {
          "cells" => [ fp_cell(key) ], "baseC" => fp_color("none"), "outlineC" => "#666666",
          "width" => 0.8, "height" => 0.8
        })
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
      when "difference_dots"
        push("difference", { "cells" => pair, "value" => dot["value"].nil? ? "" : dot["value"].to_s })
      when "ratio_dots"
        push("ratio", { "cells" => pair, "value" => dot["value"].nil? ? "" : dot["value"].to_s })
      when "inequality"
        if %w[< >].include?(dot["value"])
          # No f-puzzles equivalent: a cosmetic glyph centred on the border.
          # Stacked cells rotate the sign to point up/down.
          stacked = parse_key(cells[0])[0] != parse_key(cells[1])[0]
          glyph = stacked ? (dot["value"] == "<" ? "∧" : "∨") : dot["value"]
          push("text", { "cells" => pair, "value" => glyph, "fontC" => "#000000", "size" => 0.3 })
        end
      when "xv"
        if %w[X V].include?(dot["value"]) then push("xv", { "cells" => pair, "value" => dot["value"] })
        else @warnings << "An XV marker with no X/V letter was dropped."
        end
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
      elsif OUTER_FIELD[type]
        push(OUTER_FIELD[type], { "cell" => cell, "value" => value })
        if OUTER_UNRENDERED.include?(type) && present?(value)
          push("text", { "cells" => [ cell ], "value" => value, "fontC" => "#000000", "size" => 0.7 })
        end
      elsif OUTER_TEXT_ONLY.include?(type) && present?(value)
        push("text", { "cells" => [ cell ], "value" => value, "fontC" => "#000000", "size" => 0.7 })
      elsif type == "rossini"
        if %w[increasing decreasing].include?(clue["direction"])
          glyph = rossini_glyph(pos, clue["direction"])
          push("text", { "cells" => [ cell ], "value" => glyph, "fontC" => "#000000", "size" => 0.7 })
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
      when "slow_thermometer"
        thermo_lines(entry).each do |line|
          push("line", { "lines" => [ line ], "outlineC" => THERMO_COLOR, "width" => THERMO_STROKE_WIDTH / 64.0, "isNewConstraint" => true })
        end
        push("circle", {
          "cells" => [ fp_cell(entry["bulb"]) ], "baseC" => fp_color("none"), "outlineC" => THERMO_COLOR,
          "width" => (THERMO_BULB_RADIUS * 2) / 64.0, "height" => (THERMO_BULB_RADIUS * 2) / 64.0
        })
      when "arrow"
        push("arrow", {
          "lines" => Array(entry["arrows"]).map { |cells| Array(cells).map { |k| fp_cell(k) } },
          "cells" => Array(entry["bulbCells"]).map { |k| fp_cell(k) }
        })
      when "killer_cage"
        push("killercage", { "cells" => Array(entry["cells"]).map { |k| fp_cell(k) }, "value" => entry["sum"].nil? ? "" : entry["sum"].to_s })
      when "extra_regions"
        push("extraregion", { "cells" => Array(entry["cells"]).map { |k| fp_cell(k) } })
      when "clone"
        build_clone(entry)
      when *COSMETIC_ONLY_LINE.keys
        push("line", { "lines" => [ Array(entry["cells"]).map { |k| fp_cell(k) } ] }.merge(COSMETIC_ONLY_LINE[type]).merge("isNewConstraint" => true))
      else
        field = CONSTRAINT_LINE_FIELD[type]
        return unless field

        line_cells = Array(entry["cells"]).map { |k| fp_cell(k) }
        push(field, { "lines" => [ line_cells ] })
        cosmetic = UNRENDERED_LINE_COSMETIC[type]
        push("line", { "lines" => [ line_cells ] }.merge(cosmetic).merge("isNewConstraint" => true)) if cosmetic
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
        preset = find_preset("linePresets", line["preset"])
        push("line", {
          "lines" => [ Array(line["cells"]).map { |k| fp_cell(k) } ],
          "outlineC" => preset&.dig("style", "color") || "#777777",
          "width" => (preset&.dig("style", "strokeWidth") || 8) / 64.0
        })
      end
      Array(cosmetics["shapes"]).each { |shape| build_shape(shape) }
      Array(cosmetics["texts"]).each { |text| build_text(text) }
      Array(cosmetics["cages"]).each do |cage|
        preset = find_preset("cagePresets", cage["preset"])
        push("cage", {
          "cells" => Array(cage["cells"]).map { |k| fp_cell(k) }, "value" => cage["sum"].nil? ? "" : cage["sum"].to_s,
          "outlineC" => preset&.dig("style", "cageColor") || "#777777", "fontC" => preset&.dig("style", "textColor") || "#777777"
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
        "baseC" => fp_color(style&.dig("fillColor") || "none"),
        "outlineC" => style&.dig("strokeColor") || "#333333",
        "fontC" => style&.dig("textColor") || "#000000",
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
        "fontC" => style&.dig("color") || "#333333",
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
