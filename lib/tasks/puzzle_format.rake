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
end
