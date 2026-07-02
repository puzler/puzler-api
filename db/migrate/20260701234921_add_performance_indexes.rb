class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # Solved-play lookups (Puzzle#solved_by?, comment solved badges, the rating
    # gate) filter is_solved = TRUE; the existing partial indexes only cover
    # active (unsolved) plays.
    add_index :puzzle_plays, [ :puzzle_id, :user_id ],
      where: "is_solved", name: "index_puzzle_plays_solved_by_user"
    add_index :puzzle_plays, [ :puzzle_id, :guest_token ],
      where: "is_solved", name: "index_puzzle_plays_solved_by_guest"

    # Archive listing scans `status = published AND visibility = public`
    # (enum ints 1 and 2); neither column is indexed. A partial index matching
    # the scope keeps it cheap and small.
    add_index :puzzles, :published_at,
      order: { published_at: :desc },
      where: "status = 1 AND visibility = 2",
      name: "index_puzzles_publicly_visible"

    # Owner-facing listings ("My Puzzles" filtered by draft/published).
    add_index :puzzles, [ :author_id, :status ], name: "index_puzzles_on_author_and_status"
  end
end
