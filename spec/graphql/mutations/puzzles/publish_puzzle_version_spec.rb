require "rails_helper"

RSpec.describe "Mutation: publishPuzzleVersion / unpublishPuzzle", type: :graphql do
  let(:publish) do
    <<~GQL
      mutation($puzzleId: ID!, $versionId: ID!, $visibility: PuzzleVisibilityEnum) {
        publishPuzzleVersion(input: { puzzleId: $puzzleId, versionId: $versionId, visibility: $visibility }) {
          puzzle { id status visibility constraintTypes publishedVersion { id } }
          errors
        }
      }
    GQL
  end

  let(:unpublish) do
    <<~GQL
      mutation($id: ID!) {
        unpublishPuzzle(input: { id: $id }) {
          puzzle { id status publishedVersion { id } }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }
  let(:version) { create(:puzzle_version, puzzle:) }

  it "points the puzzle at the version and copies its constraint types", :aggregate_failures do
    vars = { puzzleId: puzzle.id, versionId: version.id, visibility: "PUBLIC" }
    data = gql_data(execute_query(publish, variables: vars, context: auth_context(user)), "publishPuzzleVersion", "puzzle")
    expect(data).to include("status" => "PUBLISHED", "visibility" => "PUBLIC")
    expect(data["publishedVersion"]["id"]).to eq(version.id.to_s)
    expect(data["constraintTypes"]).to match_array(version.constraint_types)
  end

  it "refuses to publish a version with no solution", :aggregate_failures do
    blank = create(:puzzle_version, puzzle:, solution: {})
    result = execute_query(publish, variables: { puzzleId: puzzle.id, versionId: blank.id }, context: auth_context(user))
    data = gql_data(result, "publishPuzzleVersion")
    expect(data["puzzle"]).to be_nil
    expect(data["errors"].first).to include("Solution required")
  end

  it "unpublishes back to draft and clears the pointer", :aggregate_failures do
    puzzle.update!(published_version: version, status: :published)
    result = execute_query(unpublish, variables: { id: puzzle.id }, context: auth_context(user))
    data = gql_data(result, "unpublishPuzzle", "puzzle")
    expect(data["status"]).to eq("DRAFT")
    expect(data["publishedVersion"]).to be_nil
  end
end
