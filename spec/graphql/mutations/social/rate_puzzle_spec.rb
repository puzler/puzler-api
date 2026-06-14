require "rails_helper"

RSpec.describe "Mutation: ratePuzzle", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $stars: Int, $difficultyVote: RatingDifficultyEnum) {
        ratePuzzle(input: { puzzleId: $puzzleId, stars: $stars, difficultyVote: $difficultyVote }) {
          rating { stars difficultyVote }
          errors
        }
      }
    GQL
  end

  let(:user)   { create(:user) }
  let(:puzzle) { create(:puzzle, :published) }

  context "when authenticated" do
    it "creates a rating", :aggregate_failures do
      result = execute_query(mutation,
        variables: { puzzleId: puzzle.id, stars: 5, difficultyVote: "HARD" },
        context: auth_context(user))
      expect(gql_data(result, "ratePuzzle", "rating", "stars")).to eq(5)
      expect(gql_data(result, "ratePuzzle", "rating", "difficultyVote")).to eq("HARD")
    end

    it "updates an existing rating" do
      create(:rating, puzzle: puzzle, user: user, stars: 3)
      execute_query(mutation, variables: { puzzleId: puzzle.id, stars: 5 }, context: auth_context(user))
      expect(puzzle.ratings.find_by(user: user).stars).to eq(5)
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, stars: 4 })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
