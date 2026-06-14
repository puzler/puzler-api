require "rails_helper"

RSpec.describe "Mutation: revealSolveMessage", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $solutionHash: String!, $shareToken: String) {
        revealSolveMessage(input: { puzzleId: $puzzleId, solutionHash: $solutionHash, shareToken: $shareToken }) {
          correct
          solveMessage
        }
      }
    GQL
  end

  let(:puzzle) { create(:puzzle, :published) }
  let(:version) { create(:puzzle_version, puzzle:, solve_message: "The answer is BLUE") }

  before { puzzle.update!(published_version: version) }

  it "reveals the message for a matching solution hash", :aggregate_failures do
    data = gql_data(execute_query(mutation, variables: { puzzleId: puzzle.id, solutionHash: version.solution_hash }), "revealSolveMessage")
    expect(data).to include("correct" => true, "solveMessage" => "The answer is BLUE")
  end

  it "reveals nothing for a wrong hash", :aggregate_failures do
    data = gql_data(execute_query(mutation, variables: { puzzleId: puzzle.id, solutionHash: "nope" }), "revealSolveMessage")
    expect(data).to include("correct" => false, "solveMessage" => nil)
  end

  it "stays hidden for a puzzle the viewer cannot see" do
    hidden = create(:puzzle, :access_private)
    hidden_version = create(:puzzle_version, puzzle: hidden, solve_message: "secret")
    hidden.update!(published_version: hidden_version)
    result = execute_query(mutation, variables: { puzzleId: hidden.id, solutionHash: hidden_version.solution_hash })
    expect(gql_data(result, "revealSolveMessage", "correct")).to be(false)
  end

  describe "publishedVersion.solveMessage gating" do
    let(:query) { "query($id: ID!) { puzzle(id: $id) { publishedVersion { solveMessage } } }" }

    it "is hidden from non-authors even via publishedVersion" do
      result = execute_query(query, variables: { id: puzzle.id })
      expect(gql_data(result, "puzzle", "publishedVersion", "solveMessage")).to be_nil
    end

    it "is visible to the author" do
      result = execute_query(query, variables: { id: puzzle.id }, context: auth_context(puzzle.author))
      expect(gql_data(result, "puzzle", "publishedVersion", "solveMessage")).to eq("The answer is BLUE")
    end
  end
end
