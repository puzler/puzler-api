module Mutations
  module Social
    class RatePuzzle < Mutations::BaseMutation
      description "Rate a published puzzle or cast a difficulty vote"

      argument :difficulty_vote, Types::Enums::RatingDifficultyEnum, required: false,
        description: "Difficulty assessment (easy, medium, hard, or expert)"
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
        ratings = puzzle.ratings
        puzzle.update_columns(
          avg_rating: ratings.where.not(stars: nil).average(:stars)&.round(2),
          avg_difficulty: ratings.where.not(difficulty_vote: nil).average(:difficulty_vote)&.round(2)
        )
      end
    end
  end
end
