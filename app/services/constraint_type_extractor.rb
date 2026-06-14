# Derives the flat list of constraint-type tags present in a puzzle definition
# (the frontend serializePuzzle output) so puzzles/puzzle_versions can store a
# denormalized, GIN-indexable list for archive filtering. Given digits are
# intentionally ignored — they aren't a filterable constraint.
class ConstraintTypeExtractor
  def self.extract(definition)
    return [] if definition.blank?

    data = definition.deep_stringify_keys
    types = []

    # activeConstraints is the editor's authoritative list of constraint types.
    Array(data["activeConstraints"]).each do |constraint|
      types << constraint["type"] if constraint.is_a?(Hash)
    end

    # Global variants (diagonals, chess moves, nonconsecutive, ...) and custom
    # global constraints live separately from activeConstraints.
    globals = data["globals"] || {}
    types.concat(Array(globals["variants"]))
    Array(globals["custom"]).each do |custom|
      types << custom["type"] if custom.is_a?(Hash)
    end

    types.compact.map(&:to_s).reject(&:empty?).uniq.sort
  end
end
