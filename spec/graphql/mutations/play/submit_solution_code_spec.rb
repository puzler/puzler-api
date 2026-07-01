require "rails_helper"

RSpec.describe "Mutation: submitSolutionCode", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $code: String!, $shareToken: String) {
        submitSolutionCode(input: { puzzleId: $puzzleId, code: $code, shareToken: $shareToken }) {
          solved
          recorded
          errors
        }
      }
    GQL
  end

  let(:puzzle)  { create(:puzzle, :published) }
  let(:version) { create(:puzzle_version, puzzle:, solution_code: "534 678 912") }
  let(:user)    { create(:user) }

  before { puzzle.update!(published_version: version) }

  def submit(context, code)
    execute_query(mutation, context: context, variables: { puzzleId: puzzle.id, code: code })
  end

  context "when the code matches (whitespace/case-insensitive)" do
    it "records the solve and increments solve_count", :aggregate_failures do
      expect { submit(auth_context(user), "534678912") }.to change { puzzle.reload.solve_count }.by(1)
      result = submit(auth_context(create(:user)), "  534-678-912  ".delete("-"))
      expect(gql_data(result, "submitSolutionCode", "solved")).to be true
      expect(gql_data(result, "submitSolutionCode", "recorded")).to be true
    end

    it "does not double-count a repeat claim" do
      2.times { submit(auth_context(user), "534678912") }
      expect(puzzle.reload.solve_count).to eq(1)
    end
  end

  context "when the code is wrong" do
    it "records nothing", :aggregate_failures do
      result = submit(auth_context(user), "000000000")
      expect(gql_data(result, "submitSolutionCode", "solved")).to be false
      expect(puzzle.reload.solve_count).to eq(0)
    end
  end

  context "when the author enters their own code" do
    it "confirms but does not record", :aggregate_failures do
      result = submit(auth_context(puzzle.author), "534678912")
      expect(gql_data(result, "submitSolutionCode", "solved")).to be true
      expect(gql_data(result, "submitSolutionCode", "recorded")).to be false
      expect(puzzle.reload.solve_count).to eq(0)
    end
  end

  context "when a guest claims via the code" do
    it "records a guest-hosted solve" do
      expect { submit(guest_context("guest-xyz"), "534678912") }
        .to change { puzzle.reload.solve_count }.by(1)
    end
  end

  context "when the puzzle has no solution code" do
    let(:version) { create(:puzzle_version, puzzle:, solution_code: nil) }

    it "returns an error and records nothing", :aggregate_failures do
      result = submit(auth_context(user), "anything")
      expect(gql_data(result, "submitSolutionCode", "errors")).to include(a_string_matching(/does not accept/))
      expect(puzzle.reload.solve_count).to eq(0)
    end
  end
end
