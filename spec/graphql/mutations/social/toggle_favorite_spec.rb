require "rails_helper"

RSpec.describe "Mutation: toggleFavorite", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!) {
        toggleFavorite(input: { puzzleId: $puzzleId }) {
          isFavorited
          favoriteCount
        }
      }
    GQL
  end

  let(:user)   { create(:user) }
  let(:puzzle) { create(:puzzle, :published, favorite_count: 0) }

  context "when the puzzle is not yet favorited" do
    it "adds the favorite and increments the count", :aggregate_failures do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id }, context: auth_context(user))
      data = gql_data(result, "toggleFavorite")
      expect(data["isFavorited"]).to be true
      expect(data["favoriteCount"]).to eq(1)
    end
  end

  context "when the puzzle is already favorited" do
    before { create(:favorite, puzzle: puzzle, user: user); puzzle.update!(favorite_count: 1) }

    it "removes the favorite and decrements the count", :aggregate_failures do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id }, context: auth_context(user))
      data = gql_data(result, "toggleFavorite")
      expect(data["isFavorited"]).to be false
      expect(data["favoriteCount"]).to eq(0)
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
