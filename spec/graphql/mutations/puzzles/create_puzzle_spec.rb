require "rails_helper"

RSpec.describe "Mutation: createPuzzle", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($title: String!, $gridRows: Int, $gridCols: Int) {
        createPuzzle(input: { title: $title, gridRows: $gridRows, gridCols: $gridCols }) {
          puzzle { id title grid { rows cols } status }
          errors
        }
      }
    GQL
  end

  context "when authenticated" do
    let(:user) { create(:user) }

    it "creates a draft puzzle with defaults", :aggregate_failures do
      result = execute_query(mutation, variables: { title: "My Puzzle" }, context: auth_context(user))
      data = gql_data(result, "createPuzzle")
      expect(data["errors"]).to be_empty
      expect(data["puzzle"]).to include("title" => "My Puzzle", "status" => "draft")
      expect(data["puzzle"]["grid"]).to include("rows" => 9, "cols" => 9)
    end

    it "creates a puzzle with custom grid dimensions", :aggregate_failures do
      result = execute_query(mutation, variables: { title: "6x6", gridRows: 6, gridCols: 6 }, context: auth_context(user))
      expect(gql_data(result, "createPuzzle", "puzzle", "grid", "rows")).to eq(6)
      expect(gql_data(result, "createPuzzle", "puzzle", "grid", "cols")).to eq(6)
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { title: "My Puzzle" })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
