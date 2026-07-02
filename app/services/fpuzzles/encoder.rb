module Fpuzzles
  class Error < StandardError; end
  class UnsupportedGrid < Error; end

  # Builds the f-puzzles object (and fidelity warnings) from a Puzler `definition`
  # (the stored SerializedPuzzle jsonb) plus an optional solution. Ruby port of
  # app/src/utils/sudokuPadExport.ts `puzzleToFpuzzles` — reads the serialized
  # definition rather than the editor stores, but mirrors its output (field names,
  # key order, colours) so links match the frontend byte-for-byte.
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
    ANCHOR_OFFSET = {
      "center" => [ 0, 0 ], "top" => [ -0.5, 0 ], "bottom" => [ 0.5, 0 ], "left" => [ 0, -0.5 ], "right" => [ 0, 0.5 ],
      "top-left" => [ -0.5, -0.5 ], "top-right" => [ -0.5, 0.5 ], "bottom-left" => [ 0.5, -0.5 ], "bottom-right" => [ 0.5, 0.5 ]
    }.freeze

    def self.call(definition:, solution: nil, include_solution: true, fallback_author: nil)
      new(definition, solution, include_solution, fallback_author).call
    end

    def initialize(definition, solution, include_solution, fallback_author)
      @def = (definition || {}).deep_stringify_keys
      @solution = solution
      @include_solution = include_solution
      @fallback_author = fallback_author
      @warnings = []
      @fp = {}
    end

    def call
      grid = @def["grid"] || {}
      @size = grid["rows"]
      unless @size.is_a?(Integer) && @size.positive? && @size == grid["cols"]
        raise UnsupportedGrid, "SudokuPad export needs a square grid; this puzzle is not square."
      end

      meta = @def["meta"] || {}
      @fp["size"] = @size
      @fp["title"] = meta["name"] if present?(meta["name"])
      author = present?(meta["author"]) ? meta["author"] : @fallback_author
      @fp["author"] = author if present?(author)
      @fp["ruleset"] = meta["rules"] if present?(meta["rules"])

      build_grid(grid)
      build_solution
      build_globals
      build_single_cell_marks
      build_connector_dots
      build_outer_clues
      build_instances

      Result.new(@fp, @warnings)
    end

    private

    def constraints = @def["constraints"] || {}
    def cosmetics = @def["cosmetics"] || {}
    def single_cell_marks = constraints["singleCellMarks"] || {}

    def build_grid(grid)
      color_by_id = (cosmetics["cellColorPresets"] || []).to_h { |p| [ p["id"], p["color"] ] }

      label_to_region = nil
      regions = grid["customCellRegions"]
      if present?(regions)
        labels = regions.values.compact.uniq.sort
        label_to_region = labels.each_with_index.to_h
      end

      row_index = single_cell_marks["row_index_cells"] || []
      col_index = single_cell_marks["col_index_cells"] || []
      cell_colors = cosmetics["cellColors"] || {}
      givens = @def["givenDigits"] || {}

      has_null_region = false
      cells = Array.new(@size) do |r|
        Array.new(@size) do |c|
          key = "r#{r}c#{c}"
          cell = {}
          given = givens[key]
          unless given.nil?
            cell["value"] = given
            cell["given"] = true
          end
          if label_to_region
            label = regions[key]
            if !label.nil? && label_to_region.key?(label)
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
      globals = @def["globals"] || {}
      variants = Array(globals["variants"])
      negative = []
      @fp["diagonal+"] = true if variants.include?("positive_diagonal")
      @fp["diagonal-"] = true if variants.include?("negative_diagonal")
      @fp["antiking"] = true if variants.include?("kings_move")
      @fp["antiknight"] = true if variants.include?("knights_move")
      @fp["nonconsecutive"] = true if variants.include?("nonconsecutive")
      @fp["disjointgroups"] = true if variants.include?("disjoint_sets")
      negative << "ratio" if variants.include?("anti_black_kropki")
      negative << "xv" if variants.include?("anti_x") || variants.include?("anti_v")
      %w[positive negative].each do |kind|
        next unless variants.include?("anti_#{kind}_diagonal")

        push("line", {
          "lines" => [ diagonal_cells(kind).map { |k| fp_cell(k) } ],
          "outlineC" => "#f06292", "width" => 0.05, "isNewConstraint" => true
        })
      end

      Array(globals["custom"]).each do |cg|
        if cg["type"] == "anti_diff" && cg["value"] == 1 then negative << "difference"
        elsif cg["type"] == "anti_ratio" && cg["value"] == 2 then negative << "ratio"
        else @warnings << "Custom \"#{cg['type']}\" (value #{cg['value']}) has no SudokuPad equivalent and was dropped."
        end
      end
      @fp["negative"] = negative.uniq unless negative.empty?
    end

    def build_single_cell_marks
      SINGLE_FIELD.each do |type, field|
        cells = single_cell_marks[type]
        next unless cells

        cells.each { |key| push(field, { "cell" => fp_cell(key) }) }
      end
      INDEXER_FIELD.each do |type, field|
        cells = single_cell_marks[type]
        push(field, { "cells" => cells.map { |k| fp_cell(k) } }) if cells && !cells.empty?
      end
    end

    def build_connector_dots
      (constraints["connectorDots"] || {}).each do |border_key, dot|
        if dot["type"] == "quadruples"
          corner = corner_key_to_row_col(border_key)
          next unless corner

          row, col = corner
          quad = [ "r#{row - 1}c#{col - 1}", "r#{row - 1}c#{col}", "r#{row}c#{col - 1}", "r#{row}c#{col}" ].map { |k| fp_cell(k) }
          push("quadruple", { "cells" => quad, "values" => dot["value"].is_a?(Array) ? dot["value"] : [] })
          next
        end

        a, b = border_key.split("|")
        pair = [ fp_cell(a), fp_cell(b) ]
        case dot["type"]
        when "difference_dots"
          push("difference", { "cells" => pair, "value" => dot["value"].nil? ? "" : dot["value"].to_s })
        when "ratio_dots"
          push("ratio", { "cells" => pair, "value" => dot["value"].nil? ? "" : dot["value"].to_s })
        when "inequality"
          if %w[< >].include?(dot["value"])
            # No f-puzzles equivalent: a cosmetic glyph centred on the border.
            # Stacked cells rotate the sign to point up/down at the smaller
            # (first) cell of the sorted border key.
            stacked = parse_key(a)[0] != parse_key(b)[0]
            glyph = stacked ? (dot["value"] == "<" ? "∧" : "∨") : dot["value"]
            push("text", { "cells" => pair, "value" => glyph, "fontC" => "#000000", "size" => 0.3 })
          end
        when "xv"
          if %w[X V].include?(dot["value"]) then push("xv", { "cells" => pair, "value" => dot["value"] })
          else @warnings << "An XV marker with no X/V letter was dropped."
          end
        end
      end
    end

    def build_outer_clues
      (constraints["outerClues"] || {}).each do |key, clue|
        pos = parse_outer_key(key)
        next unless pos

        cell = fp_outer_cell(pos[0], pos[1])
        value = clue["value"].nil? ? "" : clue["value"].to_s
        if clue["type"] == "little_killers"
          dir = clue["direction"] ? LITTLE_KILLER_DIR[clue["direction"]] : nil
          if dir then push("littlekillersum", { "cell" => cell, "direction" => dir, "value" => value })
          else @warnings << "A little killer with no direction was dropped."
          end
        elsif OUTER_FIELD[clue["type"]]
          push(OUTER_FIELD[clue["type"]], { "cell" => cell, "value" => value })
          if OUTER_UNRENDERED.include?(clue["type"]) && present?(value)
            push("text", { "cells" => [ cell ], "value" => value, "fontC" => "#000000", "size" => 0.7 })
          end
        end
      end
    end

    def build_instances
      (cosmetics["instances"] || []).each do |inst|
        data = inst["data"] || {}
        case inst["type"]
        when "thermometer"
          push("thermometer", { "lines" => thermo_lines(data) })
        when "slow_thermometer"
          thermo_lines(data).each do |line|
            push("line", { "lines" => [ line ], "outlineC" => THERMO_COLOR, "width" => THERMO_STROKE_WIDTH / 64.0, "isNewConstraint" => true })
          end
          push("circle", {
            "cells" => [ fp_cell(data["root"]) ], "baseC" => fp_color("none"), "outlineC" => THERMO_COLOR,
            "width" => (THERMO_BULB_RADIUS * 2) / 64.0, "height" => (THERMO_BULB_RADIUS * 2) / 64.0
          })
        when "arrow"
          push("arrow", {
            "lines" => Array(data["arrows"]).map { |p| Array(p["cells"]).map { |k| fp_cell(k) } },
            "cells" => Array(data["bulbCells"]).map { |k| fp_cell(k) }
          })
        when "killer_cage"
          push("killercage", { "cells" => Array(data["cells"]).map { |k| fp_cell(k) }, "value" => data["sum"].nil? ? "" : data["sum"].to_s })
        when "extra_regions"
          push("extraregion", { "cells" => Array(data["cells"]).map { |k| fp_cell(k) } })
        when "clone"
          Array(data["copies"]).each do |copy|
            clone_cells = Array(data["cells"]).map do |cell|
              row, col = parse_key(cell)
              fp_cell("r#{row + copy['dRow']}c#{col + copy['dCol']}")
            end
            push("clone", { "cells" => Array(data["cells"]).map { |k| fp_cell(k) }, "cloneCells" => clone_cells })
          end
        when *COSMETIC_ONLY_LINE.keys
          push("line", { "lines" => [ Array(data["cells"]).map { |k| fp_cell(k) } ] }.merge(COSMETIC_ONLY_LINE[inst["type"]]).merge("isNewConstraint" => true))
        when "cosmetic_line"
          preset = find_preset("linePresets", data["presetId"])
          push("line", {
            "lines" => [ Array(data["cells"]).map { |k| fp_cell(k) } ],
            "outlineC" => preset&.dig("style", "color") || "#777777",
            "width" => (preset&.dig("style", "strokeWidth") || 8) / 64.0
          })
        when "cosmetic_cage"
          preset = find_preset("cagePresets", data["presetId"])
          push("cage", {
            "cells" => Array(data["cells"]).map { |k| fp_cell(k) }, "value" => data["sum"].nil? ? "" : data["sum"].to_s,
            "outlineC" => preset&.dig("style", "cageColor") || "#777777", "fontC" => preset&.dig("style", "textColor") || "#777777"
          })
        when "shape"
          build_shape(data)
        when "text"
          build_text(data)
        else
          field = CONSTRAINT_LINE_FIELD[inst["type"]]
          if field
            line_cells = Array(data["cells"]).map { |k| fp_cell(k) }
            push(field, { "lines" => [ line_cells ] })
            cosmetic = UNRENDERED_LINE_COSMETIC[inst["type"]]
            push("line", { "lines" => [ line_cells ] }.merge(cosmetic).merge("isNewConstraint" => true)) if cosmetic
          end
        end
      end
    end

    def build_shape(data)
      style = find_preset("shapePresets", data["presetId"])&.dig("style")
      is_diamond = style&.dig("shapeType") == "diamond"
      field = style&.dig("shapeType") == "circle" ? "circle" : "rectangle"
      diameter = style&.dig("size") || 0.5
      entry = {
        "cells" => [ fp_pos(cosmetic_pos(data)) ],
        "baseC" => fp_color(style&.dig("fillColor") || "none"),
        "outlineC" => style&.dig("strokeColor") || "#333333",
        "fontC" => style&.dig("textColor") || "#000000",
        "width" => diameter, "height" => diameter,
        "value" => data["content"] || ""
      }
      angle = (((is_diamond ? 45 : 0) + (data["rotation"] || 0)) % 360 + 360) % 360
      entry["angle"] = angle unless angle.zero?
      push(field, entry)
    end

    def build_text(data)
      style = find_preset("textPresets", data["presetId"])&.dig("style")
      entry = {
        "cells" => [ fp_pos(cosmetic_pos(data)) ],
        "value" => data["content"] || "",
        "fontC" => style&.dig("color") || "#333333",
        "size" => (style&.dig("fontSize") || 20) / 50.0
      }
      entry["angle"] = ((data["rotation"] % 360) + 360) % 360 if present?(data["rotation"])
      push("text", entry)
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

    def parse_key(key)
      m = key.match(/\Ar(\d+)c(\d+)\z/)
      raise Error, "Invalid cell key: #{key}" unless m

      [ m[1].to_i, m[2].to_i ]
    end

    def fp_cell(key)
      row, col = parse_key(key)
      "R#{row + 1}C#{col + 1}"
    end

    def fp_color(color)
      color == "none" ? TRANSPARENT : color
    end

    def fp_pos(pos)
      "R#{fmt(pos[1] + 0.5)}C#{fmt(pos[0] + 0.5)}"
    end

    # Match JS Number→string: whole numbers without a trailing ".0".
    def fmt(num)
      num == num.to_i ? num.to_i.to_s : num.to_s
    end

    def fp_outer_cell(row, col)
      r = row.negative? ? 0 : (row >= @size ? @size + 1 : row + 1)
      c = col.negative? ? 0 : (col >= @size ? @size + 1 : col + 1)
      "R#{r}C#{c}"
    end

    def corner_key_to_row_col(key)
      m = key.match(/\A\+r(\d+)c(\d+)\z/)
      m ? [ m[1].to_i, m[2].to_i ] : nil
    end

    def parse_outer_key(key)
      m = key.match(/\Ao:r(-?\d+)c(-?\d+)\z/)
      m ? [ m[1].to_i, m[2].to_i ] : nil
    end

    def thermo_lines(data)
      adj = Hash.new { |h, k| h[k] = [] }
      Array(data["edges"]).each { |e| adj[e["from"]] << e["to"] }
      paths = []
      walk = lambda do |cell, path|
        nexts = adj[cell]
        if nexts.empty?
          paths << path
        else
          nexts.each { |n| walk.call(n, path + [ n ]) }
        end
      end
      walk.call(data["root"], [ data["root"] ])
      paths.map { |p| p.map { |k| fp_cell(k) } }
    end

    def diagonal_cells(kind)
      (0...@size).map do |i|
        row = kind == "positive" ? @size - 1 - i : i
        "r#{row}c#{i}"
      end
    end

    # pos is { "x" => , "y" => } (cell units). Mirrors cosmeticPos: free pos, else
    # legacy cell (+ anchor), else top-left cell centre. Returns [x, y].
    def cosmetic_pos(data)
      pos = data["pos"]
      return [ pos["x"], pos["y"] ] if pos.is_a?(Hash) && pos["x"] && pos["y"]

      if data["cell"]
        row, col = parse_key(data["cell"])
        dr, dc = data["anchor"] ? ANCHOR_OFFSET[data["anchor"]] : [ 0, 0 ]
        return [ col + 0.5 + dc, row + 0.5 + dr ]
      end
      [ 0.5, 0.5 ]
    end
  end
end
