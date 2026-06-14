require "rails_helper"

RSpec.describe "Mutation: deletePuzzleVersion", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($id: ID!) {
        deletePuzzleVersion(input: { id: $id }) {
          success
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }

  def delete_version(id, actor)
    gql_data(execute_query(mutation, variables: { id: }, context: auth_context(actor)), "deletePuzzleVersion")
  end

  it "deletes an unpublished version", :aggregate_failures do
    version = create(:puzzle_version, puzzle:)
    expect(delete_version(version.id, user)["success"]).to be(true)
    expect(PuzzleVersion.exists?(version.id)).to be(false)
  end

  it "refuses to delete the published version", :aggregate_failures do
    version = create(:puzzle_version, puzzle:)
    puzzle.update!(published_version: version)
    data = delete_version(version.id, user)
    expect(data).to include("success" => false, "errors" => [ a_string_including("published version") ])
    expect(PuzzleVersion.exists?(version.id)).to be(true)
  end

  it "does not delete another author's version" do
    version = create(:puzzle_version, puzzle:)
    result = execute_query(mutation, variables: { id: version.id }, context: auth_context(create(:user)))
    expect(gql_errors(result).first["message"]).to eq("Version not found")
  end
end
