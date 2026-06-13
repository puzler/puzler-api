require "rails_helper"

RSpec.describe "Mutation: savePuzzleVersion", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $definition: JSON!, $solution: JSON, $label: String) {
        savePuzzleVersion(input: { puzzleId: $puzzleId, definition: $definition, solution: $solution, label: $label }) {
          version { id versionNumber displayName label constraintTypes solutionHash isPublished }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }
  let(:definition) do
    { "version" => 2, "activeConstraints" => [ { "type" => "thermometer" } ], "globals" => { "variants" => [ "diagonal_positive" ] } }
  end

  def save_version(context, **vars)
    result = execute_query(mutation, variables: { puzzleId: puzzle.id, definition: }.merge(vars), context:)
    gql_data(result, "savePuzzleVersion")
  end

  context "when authenticated as the author" do
    it "creates v1 with derived constraint types and a hashed solution", :aggregate_failures do
      data = save_version(auth_context(user), solution: { "r0c0" => 5 })
      expect(data["errors"]).to be_empty
      expect(data["version"]).to include("versionNumber" => 1, "displayName" => "v1", "isPublished" => false)
      expect(data["version"]["constraintTypes"]).to contain_exactly("diagonal_positive", "thermometer")
      expect(data["version"]["solutionHash"]).to eq(SolutionHasher.hash("r0c0" => 5))
    end

    it "increments the version number and keeps an optional label", :aggregate_failures do
      create(:puzzle_version, puzzle:)
      version = save_version(auth_context(user), label: "Tweaked bulb")["version"]
      expect(version["versionNumber"]).to eq(2)
      expect(version["displayName"]).to eq("Tweaked bulb")
    end
  end

  context "when the puzzle belongs to someone else" do
    it "refuses to save" do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, definition: }, context: auth_context(create(:user)))
      expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, definition: })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
