require "rails_helper"

RSpec.describe "Mutation: startPlay", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!) {
        startPlay(input: { puzzleId: $puzzleId }) {
          puzzlePlay { id isSolved }
          errors
        }
      }
    GQL
  end

  let(:puzzle) { create(:puzzle, :published) }

  context "when authenticated" do
    let(:user) { create(:user) }

    it "creates a new play session", :aggregate_failures do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id }, context: auth_context(user))
      data = gql_data(result, "startPlay")
      expect(data["errors"]).to be_empty
      expect(data["puzzlePlay"]["isSolved"]).to be false
    end

    it "returns the existing unsolved play session on subsequent calls" do
      existing = create(:puzzle_play, puzzle: puzzle, user: user)
      result = execute_query(mutation, variables: { puzzleId: puzzle.id }, context: auth_context(user))
      expect(gql_data(result, "startPlay", "puzzlePlay", "id")).to eq(existing.id.to_s)
    end
  end

  context "when unauthenticated" do
    it "creates an anonymous play session", :aggregate_failures do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id })
      data = gql_data(result, "startPlay")
      expect(data["errors"]).to be_empty
      expect(data["puzzlePlay"]).not_to be_nil
    end
  end

  context "when the puzzle does not exist" do
    it "returns an error" do
      result = execute_query(mutation, variables: { puzzleId: 0 })
      expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
    end
  end
end
