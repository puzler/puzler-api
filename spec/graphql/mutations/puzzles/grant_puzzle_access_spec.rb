require "rails_helper"

RSpec.describe "Mutation: grantPuzzleAccess / revokePuzzleAccess", type: :graphql do
  let(:grant_mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $username: String!) {
        grantPuzzleAccess(input: { puzzleId: $puzzleId, username: $username }) {
          puzzle { id grantedUsers { id username } }
          errors
        }
      }
    GQL
  end

  let(:revoke_mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $userId: ID!) {
        revokePuzzleAccess(input: { puzzleId: $puzzleId, userId: $userId }) {
          puzzle { id grantedUsers { id } }
          errors
        }
      }
    GQL
  end

  let(:author)   { create(:user) }
  let!(:grantee) { create(:user, username: "grantee") }
  let(:puzzle)   { create(:puzzle, :access_private, author:) }

  it "grants a user access by username", :aggregate_failures do
    result = execute_query(grant_mutation, variables: { puzzleId: puzzle.id, username: "grantee" }, context: auth_context(author))
    data = gql_data(result, "grantPuzzleAccess")
    expect(data["errors"]).to be_empty
    expect(data["puzzle"]["grantedUsers"].map { |u| u["username"] }).to eq([ "grantee" ])
    expect(puzzle.viewable_by?(grantee)).to be(true)
  end

  it "is idempotent for a repeat grant" do
    2.times do
      execute_query(grant_mutation, variables: { puzzleId: puzzle.id, username: "grantee" }, context: auth_context(author))
    end
    expect(puzzle.access_grants.count).to eq(1)
  end

  it "errors for an unknown username", :aggregate_failures do
    result = execute_query(grant_mutation, variables: { puzzleId: puzzle.id, username: "ghost" }, context: auth_context(author))
    data = gql_data(result, "grantPuzzleAccess")
    expect(data["puzzle"]).to be_nil
    expect(data["errors"].first).to include("No user named ghost")
  end

  it "revokes access", :aggregate_failures do
    puzzle.access_grants.create!(user: grantee, granted_by: author)
    result = execute_query(revoke_mutation, variables: { puzzleId: puzzle.id, userId: grantee.id }, context: auth_context(author))
    expect(gql_data(result, "revokePuzzleAccess", "puzzle", "grantedUsers")).to be_empty
    expect(puzzle.reload.viewable_by?(grantee)).to be(false)
  end
end
