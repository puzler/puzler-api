require "rails_helper"

RSpec.describe "Mutation: updatePuzzle", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($id: ID!, $title: String, $solution: JSON) {
        updatePuzzle(input: { id: $id, attrs: { title: $title, solution: $solution } }) {
          puzzle { id title solutionHash }
          errors
        }
      }
    GQL
  end

  let(:user)   { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }

  context "when authenticated as the author" do
    it "updates the puzzle title", :aggregate_failures do
      result = execute_query(mutation, variables: { id: puzzle.id, title: "Updated Title" }, context: auth_context(user))
      data = gql_data(result, "updatePuzzle")
      expect(data["errors"]).to be_empty
      expect(data["puzzle"]["title"]).to eq("Updated Title")
    end

    it "updates the solution and recomputes the solution hash" do
      solution = { "r0c0" => 1, "r0c1" => 2 }
      result = execute_query(mutation, variables: { id: puzzle.id, solution: solution }, context: auth_context(user))
      expect(gql_data(result, "updatePuzzle", "puzzle", "solutionHash")).to eq(SolutionHasher.hash(solution))
    end
  end

  context "when authenticated as a different user" do
    it "returns a puzzle not found error" do
      other = create(:user)
      result = execute_query(mutation, variables: { id: puzzle.id, title: "Hacked" }, context: auth_context(other))
      expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { id: puzzle.id, title: "X" })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
