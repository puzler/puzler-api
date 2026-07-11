module PuzzleDefinition
  # Format-neutral helpers for reading a v4 puzzle document (@def) inside an
  # export encoder. Everything here is about the DOCUMENT's semantics — cell
  # keys, constraint tables, presets, global groups, branch-thermo flattening —
  # never about any output format. Encoders (Fpuzzles::Encoder, Scl::Encoder)
  # include this and keep their output-side mapping (coordinates, colors,
  # field names) to themselves.
  #
  # Including classes must set @def (the migrated v4 document) and may
  # override #invalid_key_error to raise their own error class from parse_key.
  module DocHelpers
    HEX_COLOR = /\A#(\h{6})(\h{2})?\z/

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

    def global_group(key)
      entry = globals[key]
      entry.is_a?(Hash) ? entry : {}
    end

    def fog_enabled?
      global_group("fog")["enabled"] == true
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

    def find_preset(kind, id)
      (cosmetics[kind] || []).find { |p| p["id"] == id }
    end

    def present?(value)
      !value.nil? && value != ""
    end

    # Bakes a 0-1 opacity into a hex color: 6-digit stays 6-digit at full
    # opacity, otherwise the alpha byte is appended (SudokuPad renders 8-digit
    # hex). An 8-digit input's own alpha multiplies with the opacity. Non-hex
    # strings (documents are lenient) pass through untouched, dropping the
    # opacity.
    def blend_opacity(color, opacity)
      return color unless opacity.is_a?(Numeric) && opacity < 1

      m = HEX_COLOR.match(color.to_s)
      return color unless m

      alpha = (m[2] ? m[2].to_i(16) / 255.0 : 1.0) * opacity.clamp(0, 1)
      byte = (alpha * 255).round
      byte >= 255 ? "##{m[1]}" : format("#%s%02x", m[1], byte)
    end

    # Document cell keys are 1-indexed; the outer clue ring is r0 / r{size+1}.
    def parse_key(key, strict: true)
      m = key.to_s.match(/\Ar(\d+)c(\d+)\z/)
      unless m
        raise invalid_key_error, "Invalid cell key: #{key}" if strict

        return nil
      end

      [ m[1].to_i, m[2].to_i ]
    end

    # Error class parse_key raises on a malformed key; encoders override.
    def invalid_key_error
      ArgumentError
    end

    # Match JS Number→string: whole numbers without a trailing ".0".
    def fmt(num)
      num == num.to_i ? num.to_i.to_s : num.to_s
    end

    # Document { bulb, lines } -> root-to-leaf paths of DOC KEYS (the
    # document's lines restart at branch points; exports repeat the shared
    # prefix). Each encoder maps the keys to its own coordinates.
    def thermo_paths(entry)
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
      paths
    end
  end
end
