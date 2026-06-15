require "rails_helper"

RSpec.describe "Mutation: checkSolution", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $board: JSON!, $shareToken: String) {
        checkSolution(input: { puzzleId: $puzzleId, board: $board, shareToken: $shareToken }) {
          result
        }
      }
    GQL
  end

  let(:puzzle) { create(:puzzle, :published) }
  # Factory solution is { "r0c0" => 5, "r0c1" => 3 }.
  let(:version) { create(:puzzle_version, puzzle:) }

  before { puzzle.update!(published_version: version) }

  def check(board, token: nil, context: {})
    gql_data(execute_query(mutation, variables: { puzzleId: puzzle.id, board:, shareToken: token }, context:), "checkSolution", "result")
  end

  it "returns SOLVED for a complete, correct board" do
    expect(check({ "r0c0" => 5, "r0c1" => 3 })).to eq("SOLVED")
  end

  it "returns CORRECT_SO_FAR for a partial board with no mistakes" do
    expect(check({ "r0c0" => 5 })).to eq("CORRECT_SO_FAR")
  end

  it "returns INCORRECT when a filled cell is wrong" do
    expect(check({ "r0c0" => 9 })).to eq("INCORRECT")
  end

  it "returns INCORRECT for a digit placed where the solution is blank" do
    expect(check({ "r0c0" => 5, "r0c1" => 3, "r0c2" => 7 })).to eq("INCORRECT")
  end

  it "ignores zero/blank entries" do
    expect(check({ "r0c0" => 5, "r0c1" => 0 })).to eq("CORRECT_SO_FAR")
  end

  it "stays coarse: a second, different mistake reads the same" do
    expect(check({ "r0c1" => 9 })).to eq("INCORRECT")
  end

  context "when the puzzle is not viewable" do
    let(:puzzle) { create(:puzzle, :access_private) }

    it "returns INCORRECT without leaking solvability" do
      expect(check({ "r0c0" => 5, "r0c1" => 3 })).to eq("INCORRECT")
    end
  end
end
