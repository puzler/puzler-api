module Sources
  # Batches "has this user completed this puzzle?" across the comments on one
  # puzzle. Grouped by puzzle_id; loaded by user_id. Keeps the comment "solved"
  # badge N+1-free even on a busy thread.
  class PuzzleSolve < GraphQL::Dataloader::Source
    def initialize(puzzle_id)
      @puzzle_id = puzzle_id
    end

    def fetch(user_ids)
      solved = PuzzlePlay.completed
                         .where(puzzle_id: @puzzle_id, user_id: user_ids)
                         .distinct.pluck(:user_id).to_set
      user_ids.map { |user_id| solved.include?(user_id) }
    end
  end
end
