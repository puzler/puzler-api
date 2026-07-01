module Mutations
  module Social
    class RatePuzzle < Mutations::BaseMutation
      description "Rate a published puzzle or cast a difficulty vote"

      argument :difficulty_vote, Integer, required: false,
        description: "Community difficulty assessment from 1 (gentlest) to 5 (hardest)"
      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle to rate"
      argument :stars, Integer, required: false,
        description: "Star rating from 1 to 5"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :rating, Types::Objects::RatingType, null: true,
        description: "The created or updated rating"

      def resolve(puzzle_id:, stars: nil, difficulty_vote: nil)
        require_auth!
        puzzle = Puzzle.publicly_visible.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        # Authors rate their own puzzle only via the author-difficulty setting, and
        # ratings are reserved for confirmed solvers (an off-site code solve counts).
        return { rating: nil, errors: [ "Authors cannot rate their own puzzle" ] } if puzzle.authored_by?(current_actor)
        return { rating: nil, errors: [ "Only solvers can rate this puzzle" ] } unless puzzle.solver?(current_user)

        rating = current_user.ratings.find_or_initialize_by(puzzle:)
        rating.stars = stars if stars
        rating.difficulty_vote = difficulty_vote if difficulty_vote

        if rating.save
          update_puzzle_averages(puzzle)
          { rating:, errors: [] }
        else
          { rating: nil, errors: rating.errors.full_messages }
        end
      end

      private

      def update_puzzle_averages(puzzle)
        puzzle.update_columns(
          avg_rating: puzzle.ratings.where.not(stars: nil).average(:stars)&.round(2)
        )
        # Community difficulty average + effective-difficulty switchover.
        puzzle.recompute_difficulty!
        # Star rating feeds the author's setter score; containers roll up too.
        puzzle.refresh_container_aggregates!
        puzzle.author.recompute_setter_stats!
      end
    end
  end
end
