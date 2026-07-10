require "rails_helper"

RSpec.describe "Mutation: savePuzzleVersion", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $attrs: PuzzleVersionAttrsInput!) {
        savePuzzleVersion(input: { puzzleId: $puzzleId, attrs: $attrs }) {
          version { id versionNumber displayName label constraintTypes solutionHash isPublished }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }
  let(:definition) do
    { "version" => 3, "activeConstraints" => [ { "type" => "thermometer" } ], "globals" => { "variants" => [ "positive_diagonal" ] } }
  end

  def save_version(context, **attrs)
    vars = { puzzleId: puzzle.id, attrs: { definition: }.merge(attrs) }
    gql_data(execute_query(mutation, variables: vars, context:), "savePuzzleVersion")
  end

  context "when authenticated as the author" do
    it "creates v1 with derived constraint types and a hashed solution", :aggregate_failures do
      data = save_version(auth_context(user), solution: { "r0c0" => 5 })
      expect(data["errors"]).to be_empty
      expect(data["version"]).to include("versionNumber" => 1, "displayName" => "v1", "isPublished" => false)
      # v3 input normalizes through the migrator: the variant keeps its group
      # chip, and every pre-v4 puzzle gains the Sudoku Rules chip.
      expect(data["version"]["constraintTypes"]).to contain_exactly("diagonals", "positive_diagonal", "sudoku_rules", "thermometer")
      expect(data["version"]["solutionHash"]).to eq(SolutionHasher.hash("r0c0" => 5))
    end

    it "increments the version number and keeps an optional label", :aggregate_failures do
      create(:puzzle_version, puzzle:)
      version = save_version(auth_context(user), label: "Tweaked bulb")["version"]
      expect(version["versionNumber"]).to eq(2)
      expect(version["displayName"]).to eq("Tweaked bulb")
    end

    it "stores a custom solve message" do
      save_version(auth_context(user), solveMessage: "Well done!")
      expect(puzzle.versions.last.solve_message).to eq("Well done!")
    end
  end

  context "when the puzzle belongs to someone else" do
    it "refuses to save" do
      vars = { puzzleId: puzzle.id, attrs: { definition: } }
      result = execute_query(mutation, variables: vars, context: auth_context(create(:user)))
      expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { puzzleId: puzzle.id, attrs: { definition: } })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
