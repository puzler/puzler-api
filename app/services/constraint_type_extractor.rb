# Derives the flat list of constraint-type tags present in a puzzle definition
# (the frontend serializePuzzle output) so puzzles/puzzle_versions can store a
# denormalized, GIN-indexable list for archive filtering. Given digits are
# intentionally ignored — they aren't a filterable constraint.
#
# Input is normalized through PuzzleDefinition::Migrator first, so pre-v4
# documents (old saved export files re-imported by clients, stale sessions)
# extract identically to their migrated form. In v4 key presence is the chip
# signal: one camelCase key per type under `constraints`/`cosmetics`, grouped
# `globals`. Output: snake_case type strings, deduped and sorted.
class ConstraintTypeExtractor
  def self.extract(definition)
    return [] if definition.blank?

    data = PuzzleDefinition::Migrator.v3_to_v4(definition.deep_stringify_keys)
    keys = PuzzleDefinition::JsonKeys::JSON_KEY_TO_TYPE
    types = (data["constraints"] || {}).keys.map { |key| keys[key] }
    # Cosmetic KIND keys map back to types; preset arrays are siblings, not kinds.
    types.concat((data["cosmetics"] || {}).keys.filter_map { |key| keys[key] })

    globals = data["globals"] || {}
    PuzzleDefinition::JsonKeys::GLOBAL_GROUPS.each do |group|
      entry = globals[group[:key]]
      next unless entry.is_a?(Hash)

      types << group[:type]
      group[:variants].each { |variant| types << variant[:type] if entry[variant[:key]] == true }
      group[:custom_values].each do |field, custom_type|
        types << custom_type if entry[field].is_a?(Array) && entry[field].any?
      end
    end
    types.compact.map(&:to_s).reject(&:empty?).uniq.sort
  end
end
