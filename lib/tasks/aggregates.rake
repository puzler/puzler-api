namespace :aggregates do
  desc "Backfill denormalized rating/solve aggregates on all collections and series"
  task backfill: :environment do
    Collection.find_each(&:recompute_aggregates!)
    Series.find_each(&:recompute_aggregates!)
    puts "Recomputed aggregates for #{Collection.count} collections and #{Series.count} series."
  end
end

namespace :difficulty do
  desc "Backfill community/effective difficulty on all puzzles"
  task backfill: :environment do
    Puzzle.find_each(&:recompute_difficulty!)
    puts "Recomputed difficulty for #{Puzzle.count} puzzles."
  end
end

namespace :setter do
  desc "Backfill denormalized setter score/tier on all users"
  task backfill: :environment do
    User.find_each(&:recompute_setter_stats!)
    puts "Recomputed setter stats for #{User.count} users."
  end
end
