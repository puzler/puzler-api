require "rails_helper"

RSpec.describe "Mutation: submitSolution", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzlePlayId: ID!, $cellState: JSON!, $timeElapsedSeconds: Int!) {
        submitSolution(input: {
          puzzlePlayId: $puzzlePlayId,
          cellState: $cellState,
          timeElapsedSeconds: $timeElapsedSeconds
        }) {
          solved
          errors
        }
      }
    GQL
  end

  let(:puzzle) { create(:puzzle, :published) }
  let(:user)   { create(:user) }
  let(:play)   { create(:puzzle_play, user: user, puzzle: puzzle) }

  # Build a cell_state that exactly matches the puzzle's solution
  let(:correct_cell_state) { puzzle.solution.transform_values { |v| { "value" => v } } }

  context "when the submitted solution is correct" do
    it "returns solved: true in the response", :aggregate_failures do
      result = execute_query(mutation, context: auth_context(user),
        variables: { puzzlePlayId: play.id, cellState: correct_cell_state, timeElapsedSeconds: 300 })
      expect(gql_data(result, "submitSolution", "solved")).to be true
      expect(gql_data(result, "submitSolution", "errors")).to be_empty
    end

    it "marks the play session as solved with elapsed time", :aggregate_failures do
      execute_query(mutation, context: auth_context(user),
        variables: { puzzlePlayId: play.id, cellState: correct_cell_state, timeElapsedSeconds: 300 })
      play.reload
      expect(play.is_solved).to be true
      expect(play.time_elapsed_seconds).to eq(300)
    end

    it "increments the puzzle's solve count" do
      expect {
        execute_query(mutation, context: auth_context(user),
          variables: { puzzlePlayId: play.id, cellState: correct_cell_state, timeElapsedSeconds: 300 })
      }.to change { puzzle.reload.solve_count }.by(1)
    end
  end

  context "when the submitted solution is incorrect" do
    it "returns solved: false and does not mark the play as solved", :aggregate_failures do
      wrong = { "r0c0" => { "value" => 0 } }
      result = execute_query(mutation, context: auth_context(user),
        variables: { puzzlePlayId: play.id, cellState: wrong, timeElapsedSeconds: 60 })
      expect(gql_data(result, "submitSolution", "solved")).to be false
      expect(play.reload.is_solved).to be false
    end
  end

  context "when attempting to submit another user's session" do
    it "returns an authorization error" do
      other = create(:user)
      result = execute_query(mutation,
        variables: { puzzlePlayId: play.id, cellState: correct_cell_state, timeElapsedSeconds: 100 },
        context: auth_context(other))
      expect(gql_errors(result).first["message"]).to eq("Not authorized")
    end
  end
end
