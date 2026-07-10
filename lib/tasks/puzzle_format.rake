namespace :puzzle_format do
  desc "Backfill stored puzzle definitions to format v4 (idempotent; skips v4 rows)"
  task migrate: :environment do
    # The migrator returns its input untouched (same object) for v4 documents,
    # so rerunning against a clean database is a no-op. The pre-backfill parity
    # harness (puzzle_format:verify + Fpuzzles::LegacyEncoder) was removed once
    # every stored definition reached v4; see git history if it's ever needed
    # against a restored v3 dataset.
    migrated = 0
    skipped = 0
    PuzzleVersion.unscoped.find_each do |version|
      next if version.definition.blank?

      definition = PuzzleDefinition::Migrator.v3_to_v4(version.definition)
      if definition.equal?(version.definition)
        skipped += 1
        next
      end

      version.update_columns(
        definition: definition,
        constraint_types: ConstraintTypeExtractor.extract(definition),
      )
      migrated += 1
    end

    # Re-sync the denormalized copy only where it actually drifted.
    resynced = 0
    Puzzle.unscoped.where.not(published_version_id: nil)
          .includes(:published_version).find_each do |puzzle|
      next if puzzle.constraint_types == puzzle.published_version.constraint_types

      puzzle.update_columns(constraint_types: puzzle.published_version.constraint_types)
      resynced += 1
    end

    puts "puzzle_format:migrate — #{migrated} migrated, #{skipped} already v4, #{resynced} puzzles re-synced."
  end

  desc "Backfill globals.sudokuRules onto stored definitions (idempotent; skips rows that carry the key)"
  task add_sudoku_rules: :environment do
    # Document semantics change (2026-07-09): the sudokuRules group's PRESENCE
    # is what means "sudoku rules apply" — an absent key now means a rules-off
    # puzzle. Every pre-change puzzle is a sudoku, so stamp the bare presence
    # marker ({} = chip active, rules enabled) onto any definition lacking it.
    backfilled = 0
    skipped = 0
    PuzzleVersion.unscoped.find_each do |version|
      definition = version.definition
      next if definition.blank?

      if definition.dig("globals", "sudokuRules")
        skipped += 1
        next
      end

      definition = definition.deep_dup
      (definition["globals"] ||= {})["sudokuRules"] = {}
      version.update_columns(
        definition: definition,
        constraint_types: ConstraintTypeExtractor.extract(definition),
      )
      backfilled += 1
    end

    # Re-sync the denormalized copy only where it actually drifted.
    resynced = 0
    Puzzle.unscoped.where.not(published_version_id: nil)
          .includes(:published_version).find_each do |puzzle|
      next if puzzle.constraint_types == puzzle.published_version.constraint_types

      puzzle.update_columns(constraint_types: puzzle.published_version.constraint_types)
      resynced += 1
    end

    puts "puzzle_format:add_sudoku_rules — #{backfilled} backfilled, #{skipped} already carried the key, #{resynced} puzzles re-synced."
  end

  desc "Stamp grid.digits onto oversized definitions that relied on the old grid-size default (idempotent)"
  task default_digits: :environment do
    # Default-digit-range change (2026-07-10, gattai epic): an absent
    # grid.digits used to mean "the grid's long side"; it now means "the long
    # side capped at 9" so oversized boards can't overflow the solver's 16-cap
    # candidate masks. Pre-change puzzles between 10 and 16 relied on the old
    # meaning — stamp it explicitly so their digit range doesn't silently
    # shrink to 9. (Nothing above 16 exists yet: 16 was the frontend cap.)
    backfilled = 0
    skipped = 0
    PuzzleVersion.unscoped.find_each do |version|
      definition = version.definition
      next if definition.blank?

      grid = definition["grid"]
      next if grid.blank?

      long_side = [ grid["rows"].to_i, grid["cols"].to_i ].max
      unless grid["digits"].nil? && long_side.between?(10, 16)
        skipped += 1
        next
      end

      definition = definition.deep_dup
      definition["grid"]["digits"] = long_side
      version.update_columns(definition: definition)
      backfilled += 1
    end

    puts "puzzle_format:default_digits — #{backfilled} backfilled, #{skipped} unaffected."
  end
end
