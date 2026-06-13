require "rails_helper"

RSpec.describe "Mutation: updatePuzzleVersionLabel", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($id: ID!, $label: String) {
        updatePuzzleVersionLabel(input: { id: $id, label: $label }) {
          version { id label displayName }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }
  let(:version) { create(:puzzle_version, puzzle:) }

  it "renames a version" do
    result = execute_query(mutation, variables: { id: version.id, label: "Release" }, context: auth_context(user))
    expect(gql_data(result, "updatePuzzleVersionLabel", "version")).to include("label" => "Release", "displayName" => "Release")
  end

  it "clears the label back to the v{n} default when given null", :aggregate_failures do
    version.update!(label: "Old")
    result = execute_query(mutation, variables: { id: version.id, label: nil }, context: auth_context(user))
    data = gql_data(result, "updatePuzzleVersionLabel", "version")
    expect(data["label"]).to be_nil
    expect(data["displayName"]).to eq("v#{version.version_number}")
  end

  it "does not rename another author's version" do
    result = execute_query(mutation, variables: { id: version.id, label: "Nope" }, context: auth_context(create(:user)))
    expect(gql_errors(result).first["message"]).to eq("Version not found")
  end
end
