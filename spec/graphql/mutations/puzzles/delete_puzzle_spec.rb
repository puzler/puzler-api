require "rails_helper"

RSpec.describe "Mutation: deletePuzzle", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($id: ID!) {
        deletePuzzle(input: { id: $id }) {
          success
        }
      }
    GQL
  end

  let(:user)    { create(:user) }
  let!(:puzzle) { create(:puzzle, author: user) }

  context "when authenticated as the author" do
    it "deletes the puzzle and returns success", :aggregate_failures do
      result = execute_query(mutation, variables: { id: puzzle.id }, context: auth_context(user))
      expect(gql_data(result, "deletePuzzle", "success")).to be true
      expect(Puzzle.find_by(id: puzzle.id)).to be_nil
    end
  end

  context "when authenticated as a different user" do
    it "returns a puzzle not found error" do
      other = create(:user)
      result = execute_query(mutation, variables: { id: puzzle.id }, context: auth_context(other))
      expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { id: puzzle.id })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
