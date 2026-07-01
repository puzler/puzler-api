require "rails_helper"

RSpec.describe "Mutation: ratePuzzle", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $stars: Int, $difficultyVote: Int) {
        ratePuzzle(input: { puzzleId: $puzzleId, stars: $stars, difficultyVote: $difficultyVote }) {
          rating { stars difficultyVote }
          errors
        }
      }
    GQL
  end

  let(:user)   { create(:user) }
  let(:puzzle) { create(:puzzle, :published) }

  context "when a confirmed solver rates" do
    # Ratings are gated to solvers, so credit the rater with a completed play.
    before { create(:puzzle_play, :solved, user: user, puzzle: puzzle) }

    it "creates a rating", :aggregate_failures do
      result = execute_query(mutation,
        variables: { puzzleId: puzzle.id, stars: 5, difficultyVote: 4 },
        context: auth_context(user))
      expect(gql_data(result, "ratePuzzle", "rating", "stars")).to eq(5)
      expect(gql_data(result, "ratePuzzle", "rating", "difficultyVote")).to eq(4)
    end

    it "updates an existing rating" do
      create(:rating, puzzle: puzzle, user: user, stars: 3)
      execute_query(mutation, variables: { puzzleId: puzzle.id, stars: 5 }, context: auth_context(user))
      expect(puzzle.ratings.find_by(user: user).stars).to eq(5)
    end

    it "rejects a difficulty vote outside 1-5" do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, difficultyVote: 7 }, context: auth_context(user))
      expect(gql_data(result, "ratePuzzle", "errors")).to be_present
    end

    it "recomputes the puzzle's community difficulty", :aggregate_failures do
      execute_query(mutation, variables: { puzzleId: puzzle.id, difficultyVote: 4 }, context: auth_context(user))
      expect(puzzle.reload.avg_difficulty).to eq(4.0)
      expect(puzzle.difficulty_vote_count).to eq(1)
    end
  end

  context "when the rater has not solved the puzzle" do
    it "is rejected", :aggregate_failures do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, stars: 4 }, context: auth_context(user))
      expect(gql_data(result, "ratePuzzle", "rating")).to be_nil
      expect(gql_data(result, "ratePuzzle", "errors")).to include(a_string_matching(/solvers/))
    end
  end

  context "when the author rates their own puzzle" do
    before { create(:puzzle_play, :solved, user: puzzle.author, puzzle: puzzle) }

    it "is rejected even after playing it", :aggregate_failures do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, stars: 5 }, context: auth_context(puzzle.author))
      expect(gql_data(result, "ratePuzzle", "rating")).to be_nil
      expect(gql_data(result, "ratePuzzle", "errors")).to include(a_string_matching(/Authors cannot rate/))
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, stars: 4 })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
