module PuzzleDefinition
  # Migrates pre-v4 puzzle definitions (stored v3 documents and v1/v2-era
  # blobs) to format v4. Ruby port of the frontend migrator + document builder
  # (app/src/utils/puzzleMigrate.ts snapshotFromV3 and
  # app/src/utils/puzzleExport.ts buildDocument, sharing the boundary
  # conversions from app/src/utils/puzzleFormat.ts) — the two sides must
  # produce the same v4 document for the same v3 input.
  #
  # Pure and idempotent: input at formatVersion/version >= 4 is returned
  # untouched — the version check is the guard that keeps the 1-index shift
  # from ever applying twice. Output is a fresh string-keyed hash whose keys
  # appear in registry-canonical order (JsonKeys insertion order).
  class Migrator
    FORMAT_VERSION = 4

    CELL_KEY_RE = /\Ar(-?\d+)c(-?\d+)\z/
    OUTER_KEY_RE = /\Ao:r(-?\d+)c(-?\d+)\z/
    CORNER_KEY_RE = /\A\+r(\d+)c(\d+)\z/

    # Preset ids canonicalize to positional slugs on every serialize.
    PRESET_SLUG_PREFIX = {
      "cosmetic_line" => "line",
      "cosmetic_border" => "border",
      "shape" => "shape",
      "text" => "text",
      "cell_color" => "color",
      "cosmetic_cage" => "cage"
    }.freeze

    # Anchor -> [dr, dc] offset (in cells) from a cell centre; used to migrate
    # legacy v2-era shape/text data (cell + anchor) to a free `pos`.
    SHAPE_ANCHOR_OFFSET = {
      "center" => [ 0, 0 ],
      "top" => [ -0.5, 0 ], "bottom" => [ 0.5, 0 ], "left" => [ 0, -0.5 ], "right" => [ 0, 0.5 ],
      "top-left" => [ -0.5, -0.5 ], "top-right" => [ -0.5, 0.5 ],
      "bottom-left" => [ 0.5, -0.5 ], "bottom-right" => [ 0.5, 0.5 ]
    }.freeze

    def self.v3_to_v4(definition)
      return definition if definition.blank?

      data = definition.deep_stringify_keys
      version = data["formatVersion"] || data["version"] || 0
      return definition if version.is_a?(Numeric) && version >= FORMAT_VERSION

      new(data).document
    end

    # Standard box layout math (port of regionsForSize/boxIndexToLabel from
    # app/src/stores/grid.ts). Public: the parity harness normalizes f-puzzles
    # region output against the same standard layout.
    def self.regions_for_size(size)
      height, width = box_dimensions_for_size(size)
      regions_per_row = size / width
      Array.new(size) do |row|
        Array.new(size) { |col| (row / height) * regions_per_row + (col / width) }
      end
    end

    def self.box_dimensions_for_size(size)
      factors = (1..Integer.sqrt(size)).each_with_object([]) do |i, list|
        next unless (size % i).zero?

        list << i
        list << size / i unless size / i == i
      end
      factors.sort!
      [ factors[(factors.length - 1) / 2], factors[(factors.length - 1).fdiv(2).ceil] ]
    end

    def self.box_index_to_label(index)
      return (index + 1).to_s if index < 9

      code = "A".ord + (index - 9)
      code <= "Z".ord ? code.chr : "?"
    end

    def initialize(data)
      @doc = data
    end

    def document
      build_document(snapshot_from_v3)
    end

    private

    # ── v3 → store-shaped snapshot (port of snapshotFromV3) ──────────────────

    def snapshot_from_v3
      meta = @doc["meta"] || {}
      globals = @doc["globals"] || {}
      constraints = @doc["constraints"] || {}
      cosmetics = @doc["cosmetics"] || {}
      grid = @doc["grid"] || {}
      text_presets = cosmetics["textPresets"] || []

      {
        rows: grid["rows"],
        cols: grid["cols"],
        custom_cell_regions: grid["customCellRegions"],
        meta: {
          "name" => meta["name"] || "",
          "author" => meta["author"] || "",
          "rules" => meta["rules"] || "",
          "solveMessage" => meta["solveMessage"] || ""
        },
        solution: @doc["solution"],
        given_digits: @doc["givenDigits"] || {},
        # Pre-v4 puzzles are always sudoku: give them the Sudoku Rules chip,
        # whose document presence is what now means "sudoku rules apply".
        active_types: Array(@doc["activeConstraints"]).filter_map { |c| c["type"] if c.is_a?(Hash) }.to_set << "sudoku_rules",
        variants: Array(globals["variants"]).to_set,
        custom_globals: Array(globals["custom"]).map { |c| { type: c["type"], value: c["value"] } },
        single_cell_marks: (constraints["singleCellMarks"] || {}).transform_values(&:sort),
        connector_dots: (constraints["connectorDots"] || {}).map do |location, dot|
          { type: dot["type"], location: location, value: dot["value"] }
        end,
        outer_clues: (constraints["outerClues"] || {}).map do |location, clue|
          {
            type: clue["type"], location: location, value: clue["value"],
            direction: clue["direction"], rossini_direction: clue["rossiniDirection"]
          }
        end,
        instances: migrated_instances(cosmetics, text_presets),
        cell_colors: cosmetics["cellColors"] || {},
        presets: {
          "cosmetic_line" => cosmetics["linePresets"] || [],
          # Cosmetic borders did not exist before v4.
          "cosmetic_border" => [],
          "shape" => migrated_shape_presets(cosmetics),
          "text" => text_presets,
          "cell_color" => cosmetics["cellColorPresets"] || [],
          "cosmetic_cage" => cosmetics["cagePresets"] || []
        }
      }
    end

    # Legacy shape preset sizing: a single `size` fraction becomes explicit
    # width/height (sizeLinked is derived on load and dropped from documents).
    def migrated_shape_presets(cosmetics)
      (cosmetics["shapePresets"] || []).map do |preset|
        style = (preset["style"] || {}).except("size")
        size = preset.dig("style", "size")
        width = first_defined(style["width"], size, 0.5)
        height = first_defined(style["height"], size, width)
        {
          "id" => preset["id"],
          "label" => preset["label"],
          "style" => style.merge("width" => width, "height" => height, "sizeLinked" => width == height)
        }
      end
    end

    # Legacy text/shape cosmetics: instances used to be pinned to a cell
    # (+ anchor) with shared preset content — resolve each to its own free
    # `pos` and `content` so the document builder sees the modern model.
    def migrated_instances(cosmetics, text_presets)
      Array(cosmetics["instances"]).map do |inst|
        type = inst["type"]
        data = inst["data"] || {}
        next { type: type, data: data } unless %w[text shape].include?(type)

        content = data["content"]
        if content.nil?
          preset = text_presets.find { |p| p["id"] == data["presetId"] }
          content = type == "text" ? (preset&.dig("content") || "?") : ""
        end
        migrated = { "presetId" => data["presetId"], "pos" => cosmetic_pos(data), "content" => content }
        migrated["rotation"] = data["rotation"] if js_truthy?(data["rotation"])
        { type: type, data: migrated }
      end
    end

    # Resolve a text/shape instance's free position, falling back to its legacy
    # cell (+ anchor) for puzzles saved before per-instance positioning.
    def cosmetic_pos(data)
      pos = data["pos"]
      return { "x" => pos["x"], "y" => pos["y"] } if pos.is_a?(Hash)

      if data["cell"]
        row, col = parse_cell_key(data["cell"])
        dr, dc = data["anchor"] ? SHAPE_ANCHOR_OFFSET.fetch(data["anchor"]) : [ 0, 0 ]
        return { "x" => col + 0.5 + dc, "y" => row + 0.5 + dr }
      end
      { "x" => 0.5, "y" => 0.5 }
    end

    # ── snapshot → v4 document (port of buildDocument) ───────────────────────

    def build_document(snap)
      slugs = build_slug_maps(snap[:presets])

      globals = build_globals(snap)
      constraints = {}
      cosmetics = {}
      JsonKeys::TYPE_TO_JSON_KEY.each do |type, key|
        category = JsonKeys.category(type)
        next if category == :global
        next unless snap[:active_types].include?(type) || type_has_data?(snap, type)

        if category == :cosmetic
          cosmetics[key] = doc_cosmetic_entry(snap, type, slugs)
          presets_key = JsonKeys::PRESETS_KEY_BY_TYPE.fetch(type)
          cosmetics[presets_key] = doc_presets(type, snap[:presets].fetch(type), slugs)
        else
          constraints[key] = doc_constraint_entry(snap, type)
        end
      end

      meta = snap[:meta].reject { |_k, v| v.nil? || v == "" }
      regions = regions_to_doc(snap[:custom_cell_regions], snap[:rows], snap[:cols])
      grid = { "rows" => snap[:rows], "cols" => snap[:cols] }
      grid["regions"] = regions if regions

      doc = { "formatVersion" => FORMAT_VERSION, "grid" => grid }
      doc["meta"] = meta unless meta.empty?
      doc["solution"] = shift_map_keys(snap[:solution], 1) if snap[:solution].is_a?(Hash) && !snap[:solution].empty?
      doc["givenDigits"] = shift_map_keys(snap[:given_digits], 1) unless snap[:given_digits].empty?
      doc["globals"] = globals unless globals.empty?
      doc["constraints"] = constraints unless constraints.empty?
      doc["cosmetics"] = cosmetics unless cosmetics.empty?
      doc
    end

    def build_globals(snap)
      globals = {}
      JsonKeys::GLOBAL_GROUPS.each do |group|
        entry = {}
        group[:variants].each do |variant|
          entry[variant[:key]] = true if snap[:variants].include?(variant[:type])
        end
        group[:custom_values].each do |field, custom_type|
          values = snap[:custom_globals].filter_map { |c| c[:value] if c[:type] == custom_type }.sort
          entry[field] = values unless values.empty?
        end
        globals[group[:key]] = entry if snap[:active_types].include?(group[:type]) || !entry.empty?
      end
      globals
    end

    def type_has_data?(snap, type)
      case JsonKeys.category(type)
      when :single_cell then (snap[:single_cell_marks][type] || []).any?
      when :connector then snap[:connector_dots].any? { |d| d[:type] == type }
      when :outer then snap[:outer_clues].any? { |c| c[:type] == type }
      when :cosmetic
        return !snap[:cell_colors].empty? if type == "cell_color"

        snap[:instances].any? { |i| i[:type] == type }
      else
        snap[:instances].any? { |i| i[:type] == type }
      end
    end

    def doc_constraint_entry(snap, type)
      case JsonKeys.category(type)
      when :single_cell then doc_cells(snap[:single_cell_marks][type] || [])
      when :connector then doc_connector_entries(snap, type)
      when :outer then doc_outer_entries(snap, type)
      else
        snap[:instances].select { |i| i[:type] == type }.map { |i| doc_instance_data(type, i[:data]) }
      end
    end

    def doc_connector_entries(snap, type)
      snap[:connector_dots].select { |d| d[:type] == type }.map do |dot|
        if type == "quadruples"
          { "cells" => corner_location_to_doc_cells(dot[:location]),
            "values" => dot[:value].is_a?(Array) ? dot[:value].dup : [] }
        else
          entry = { "cells" => border_location_to_doc_cells(dot[:location]) }
          entry["value"] = dot[:value] unless dot[:value].nil? || dot[:value].is_a?(Array)
          entry
        end
      end
    end

    def doc_outer_entries(snap, type)
      snap[:outer_clues].select { |c| c[:type] == type }.map do |clue|
        entry = { "cell" => doc_outer_cell(clue[:location]) }
        entry["value"] = clue[:value] unless clue[:value].nil?
        # Rossini clues carry an arrow, not a value; the document calls both
        # direction fields `direction` (the type disambiguates).
        if type == "rossini"
          entry["direction"] = clue[:rossini_direction] || "increasing"
        elsif js_truthy?(clue[:direction])
          entry["direction"] = clue[:direction]
        end
        entry
      end
    end

    def doc_instance_data(type, data)
      if JsonKeys::THERMO_TYPES.include?(type)
        return {
          "bulb" => doc_cell(data["root"].to_s),
          "lines" => thermo_edges_to_lines(data["root"], Array(data["edges"])).map { |line| doc_cells(line) }
        }
      end

      case type
      when "arrow"
        { "bulbCells" => doc_cells(Array(data["bulbCells"])),
          "arrows" => Array(data["arrows"]).map { |path| doc_cells(Array(path["cells"])) } }
      when "killer_cage"
        entry = { "cells" => doc_cells(Array(data["cells"])) }
        entry["sum"] = data["sum"] unless data["sum"].nil?
        entry
      when "extra_regions"
        { "cells" => doc_cells(Array(data["cells"])) }
      when "clone"
        { "cells" => doc_cells(Array(data["cells"])), "copies" => Array(data["copies"]).map(&:dup) }
      else
        { "cells" => doc_cells(Array(data["cells"])) }
      end
    end

    def doc_cosmetic_entry(snap, type, slugs)
      if type == "cell_color"
        return snap[:cell_colors].each_with_object({}) do |(cell, id), out|
          out[shift_cell_key(cell, 1)] = slugs.fetch("cell_color")[id] || id
        end
      end

      snap[:instances].select { |i| i[:type] == type }.map do |inst|
        data = inst[:data]
        case type
        when "cosmetic_line"
          { "cells" => doc_cells(Array(data["cells"])),
            "preset" => slugs.fetch("cosmetic_line")[data["presetId"]] || data["presetId"] }
        when "cosmetic_cage"
          entry = { "cells" => doc_cells(Array(data["cells"])) }
          entry["sum"] = data["sum"] unless data["sum"].nil?
          entry["preset"] = slugs.fetch("cosmetic_cage")[data["presetId"]] || data["presetId"]
          entry
        else # text / shape: free-positioned, content-carrying
          pos = cosmetic_pos(data)
          entry = { "pos" => { "x" => pos["x"] + 1, "y" => pos["y"] + 1 } }
          entry["content"] = data["content"] if js_truthy?(data["content"])
          entry["rotation"] = data["rotation"] if js_truthy?(data["rotation"])
          entry["preset"] = slugs.fetch(type)[data["presetId"]] || data["presetId"]
          entry
        end
      end
    end

    def build_slug_maps(presets)
      presets.to_h do |kind, list|
        [ kind, list.each_with_index.to_h { |p, i| [ p["id"], "#{PRESET_SLUG_PREFIX.fetch(kind)}-#{i + 1}" ] } ]
      end
    end

    def doc_presets(kind, presets, slugs)
      presets.map do |preset|
        entry = { "id" => slugs.fetch(kind)[preset["id"]] || preset["id"] }
        entry["label"] = preset["label"] unless preset["label"].nil?
        if kind == "cell_color"
          entry["color"] = preset["color"] unless preset["color"].nil?
        else
          style = preset["style"] || {}
          # sizeLinked is editor UX state (width/height inputs mirroring),
          # derived as width == height on load — never part of the document.
          entry["style"] = kind == "shape" ? style.except("sizeLinked") : style.dup
        end
        entry
      end
    end

    # ── boundary conversions (port of puzzleFormat.ts) ───────────────────────
    # The document is 1-indexed (`r1c1` = top-left); v3 stored 0-indexed
    # internal keys. The outer clue ring becomes `r0` / `r{rows+1}`.

    def shift_cell_key(key, delta)
      m = CELL_KEY_RE.match(key)
      return key unless m # malformed keys pass through; validation reports them

      "r#{m[1].to_i + delta}c#{m[2].to_i + delta}"
    end

    def doc_cell(key)
      shift_cell_key(key, 1)
    end

    def doc_cells(keys)
      keys.map { |key| doc_cell(key) }
    end

    def shift_map_keys(map, delta)
      map.to_h { |key, value| [ shift_cell_key(key, delta), value ] }
    end

    # Internal `o:r-1c3` -> document `r0c4`.
    def doc_outer_cell(location)
      m = OUTER_KEY_RE.match(location)
      return location unless m

      "r#{m[1].to_i + 1}c#{m[2].to_i + 1}"
    end

    # Border key `r4c4|r4c5` -> document cell pair; corner key `+r4c4` -> the
    # 2x2 document block whose shared corner it names (reading order).
    def border_location_to_doc_cells(location)
      location.split("|").map { |key| doc_cell(key) }
    end

    def corner_location_to_doc_cells(location)
      m = CORNER_KEY_RE.match(location)
      return [] unless m

      # Internal corner (r, c) = document top-left cell (r, c).
      row = m[1].to_i
      col = m[2].to_i
      [ "r#{row}c#{col}", "r#{row}c#{col + 1}", "r#{row + 1}c#{col}", "r#{row + 1}c#{col + 1}" ]
    end

    # Internal { root, edges } -> document lines: each line is a cell path
    # starting at the bulb or at a branch point. The walk follows edge order,
    # so hydrating the document reproduces the same edge adjacency.
    def thermo_edges_to_lines(root, edges)
      lines = []
      used = Array.new(edges.length, false)
      reached = Set.new([ root ])
      remaining = edges.length
      while remaining.positive?
        start = edges.each_index.find { |i| !used[i] && reached.include?(edges[i]["from"]) }
        break if start.nil? # edges disconnected from the bulb: dropped

        line = [ edges[start]["from"], edges[start]["to"] ]
        used[start] = true
        remaining -= 1
        reached << edges[start]["to"]
        loop do
          tail = line.last
          next_idx = edges.each_index.find { |i| !used[i] && edges[i]["from"] == tail }
          break if next_idx.nil?

          line << edges[next_idx]["to"]
          used[next_idx] = true
          remaining -= 1
          reached << edges[next_idx]["to"]
        end
        lines << line
      end
      lines
    end

    # ── regions (region-first document form) ─────────────────────────────────
    # `grid.regions` maps region label -> complete cell list; omitted entirely
    # = standard box layout; a cell listed nowhere = regionless. v3 stored a
    # sparse per-cell override map, so migration expands it against the
    # standard layout, and omits the key when nothing effectively differs.

    def regions_to_doc(overrides, rows, cols)
      return nil if overrides.nil?

      standard = rows == cols ? self.class.regions_for_size(rows) : nil
      regions = {}
      differs = false
      (0...rows).each do |r|
        (0...cols).each do |c|
          standard_label = standard && self.class.box_index_to_label(standard[r][c])
          key = "r#{r}c#{c}"
          label = overrides.key?(key) ? overrides[key] : standard_label
          differs = true if label != standard_label
          (regions[label] ||= []) << "r#{r + 1}c#{c + 1}" unless label.nil?
        end
      end
      return nil unless differs

      regions.keys.sort.index_with { |label| regions[label] }
    end

    # ── small JS-semantics helpers ───────────────────────────────────────────

    def parse_cell_key(key)
      m = CELL_KEY_RE.match(key.to_s)
      m ? [ m[1].to_i, m[2].to_i ] : [ 0, 0 ]
    end

    # Mirrors JS truthiness for the values these fields can hold (the TS
    # serializer drops falsy content/rotation/direction).
    def js_truthy?(value)
      !(value.nil? || value == false || value == 0 || value == "")
    end

    # Mirrors JS `??` (nil-coalescing, unlike Ruby `||` for false/0).
    def first_defined(*values)
      values.find { |v| !v.nil? }
    end
  end
end
