require "rails_helper"

RSpec.describe "Query: puzzleByToken", type: :graphql do
  let(:query) do
    <<~GQL
      query($token: String!) {
        puzzleByToken(token: $token) { id title }
      }
    GQL
  end

  it "resolves an unlisted puzzle by its share token" do
    puzzle = create(:puzzle, :unlisted)
    result = execute_query(query, variables: { token: puzzle.share_token })
    expect(gql_data(result, "puzzleByToken", "id")).to eq(puzzle.id.to_s)
  end

  it "returns nil for a private puzzle even with the right token" do
    puzzle = create(:puzzle, :access_private)
    result = execute_query(query, variables: { token: puzzle.share_token })
    expect(gql_data(result, "puzzleByToken")).to be_nil
  end

  it "returns nil for an unknown token" do
    result = execute_query(query, variables: { token: "nope" })
    expect(gql_data(result, "puzzleByToken")).to be_nil
  end
end
