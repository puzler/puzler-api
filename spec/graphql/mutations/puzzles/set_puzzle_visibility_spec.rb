require "rails_helper"

RSpec.describe "Mutation: setPuzzleVisibility", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($id: ID!, $visibility: PuzzleVisibilityEnum!) {
        setPuzzleVisibility(input: { id: $id, visibility: $visibility }) {
          puzzle { id visibility }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }

  it "changes the access mode" do
    result = execute_query(mutation, variables: { id: puzzle.id, visibility: "UNLISTED" }, context: auth_context(user))
    expect(gql_data(result, "setPuzzleVisibility", "puzzle", "visibility")).to eq("UNLISTED")
  end

  it "allows the container-only tier" do
    result = execute_query(mutation, variables: { id: puzzle.id, visibility: "CONTAINERS_ONLY" }, context: auth_context(user))
    expect(gql_data(result, "setPuzzleVisibility", "puzzle", "visibility")).to eq("CONTAINERS_ONLY")
  end

  it "rejects the not-yet-selectable patron tier", :aggregate_failures do
    result = execute_query(mutation, variables: { id: puzzle.id, visibility: "PATRONS_ONLY" }, context: auth_context(user))
    data = gql_data(result, "setPuzzleVisibility")
    expect(data["puzzle"]).to be_nil
    expect(data["errors"].first).to include("Unsupported visibility")
  end

  it "does not let a non-owner change visibility" do
    result = execute_query(mutation, variables: { id: puzzle.id, visibility: "PUBLIC" }, context: auth_context(create(:user)))
    expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
  end
end
