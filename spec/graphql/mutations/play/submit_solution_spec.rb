require "rails_helper"

RSpec.describe "Mutation: submitSolution", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $cellState: JSON!, $timeElapsedSeconds: Int!, $shareToken: String) {
        submitSolution(input: {
          puzzleId: $puzzleId,
          cellState: $cellState,
          timeElapsedSeconds: $timeElapsedSeconds,
          shareToken: $shareToken
        }) {
          solved
          recorded
          errors
        }
      }
    GQL
  end

  let(:puzzle) { create(:puzzle, :published) }
  let(:user)   { create(:user) }

  # A cell_state that exactly matches the puzzle's solution.
  let(:correct_cell_state) { puzzle.solution.transform_values { |v| { "value" => v } } }

  def submit(context, cell_state: correct_cell_state, seconds: 300)
    execute_query(mutation, context: context,
      variables: { puzzleId: puzzle.id, cellState: cell_state, timeElapsedSeconds: seconds })
  end

  context "when a non-author submits a correct board" do
    it "confirms and records the solve", :aggregate_failures do
      result = submit(auth_context(user))
      expect(gql_data(result, "submitSolution", "solved")).to be true
      expect(gql_data(result, "submitSolution", "recorded")).to be true
      expect(gql_data(result, "submitSolution", "errors")).to be_empty
    end

    it "creates a completed play and increments solve_count", :aggregate_failures do
      expect { submit(auth_context(user)) }.to change { puzzle.reload.solve_count }.by(1)
      play = puzzle.puzzle_plays.completed.find_by(user: user)
      expect(play.time_elapsed_seconds).to eq(300)
    end

    it "does not double-count a repeat solve" do
      2.times { submit(auth_context(user)) }
      expect(puzzle.reload.solve_count).to eq(1)
    end
  end

  context "when the submitted board is incorrect" do
    it "returns solved: false and records nothing", :aggregate_failures do
      result = submit(auth_context(user), cell_state: { "r0c0" => { "value" => 0 } }, seconds: 60)
      expect(gql_data(result, "submitSolution", "solved")).to be false
      expect(puzzle.reload.solve_count).to eq(0)
    end
  end

  context "when the puzzle's author submits their own solution" do
    it "confirms the solve but does not record it", :aggregate_failures do
      result = submit(auth_context(puzzle.author))
      expect(gql_data(result, "submitSolution", "solved")).to be true
      expect(gql_data(result, "submitSolution", "recorded")).to be false
      expect(puzzle.reload.solve_count).to eq(0)
    end
  end

  context "when a solo guest submits a correct board" do
    let(:guest_token) { "guest-abc-123" }

    it "records a guest-hosted completed play once", :aggregate_failures do
      expect { submit(guest_context(guest_token)) }.to change { puzzle.reload.solve_count }.by(1)
      expect(puzzle.puzzle_plays.guest_hosted.completed.exists?(guest_token: guest_token)).to be true
    end

    it "does not double-count a repeat guest submission" do
      2.times { submit(guest_context(guest_token)) }
      expect(puzzle.reload.solve_count).to eq(1)
    end
  end
end
