require "rails_helper"

RSpec.describe "Mutation: saveProgress", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzlePlayId: ID!, $cellState: JSON!, $timeElapsedSeconds: Int!) {
        saveProgress(input: {
          puzzlePlayId: $puzzlePlayId,
          cellState: $cellState,
          timeElapsedSeconds: $timeElapsedSeconds
        }) {
          puzzlePlay { id timeElapsedSeconds }
          errors
        }
      }
    GQL
  end

  let(:cell_state) { { "r0c0" => { "value" => 5 } } }

  context "when saving an authenticated user's session" do
    let(:user) { create(:user) }
    let(:play) { create(:puzzle_play, :with_user, user: user) }

    it "saves progress", :aggregate_failures do
      result = execute_query(mutation,
        variables: { puzzlePlayId: play.id, cellState: cell_state, timeElapsedSeconds: 120 },
        context: auth_context(user))
      expect(gql_data(result, "saveProgress", "errors")).to be_empty
      expect(gql_data(result, "saveProgress", "puzzlePlay", "timeElapsedSeconds")).to eq(120)
    end
  end

  context "when saving an anonymous session" do
    let(:play) { create(:puzzle_play) }

    it "saves progress without authentication" do
      result = execute_query(mutation,
        variables: { puzzlePlayId: play.id, cellState: cell_state, timeElapsedSeconds: 60 })
      expect(gql_data(result, "saveProgress", "errors")).to be_empty
    end
  end

  context "when attempting to save another user's session" do
    let(:owner) { create(:user) }
    let(:other) { create(:user) }
    let(:play)  { create(:puzzle_play, :with_user, user: owner) }

    it "returns an authorization error" do
      result = execute_query(mutation,
        variables: { puzzlePlayId: play.id, cellState: cell_state, timeElapsedSeconds: 10 },
        context: auth_context(other))
      expect(gql_errors(result).first["message"]).to eq("Not authorized")
    end
  end

  context "with full session state" do
    let(:user) { create(:user) }
    let(:play) { create(:puzzle_play, :with_user, user: user) }
    let(:mutation_with_progress) do
      <<~GQL
        mutation($puzzlePlayId: ID!, $cellState: JSON!, $timeElapsedSeconds: Int!, $progressState: JSON!) {
          saveProgress(input: {
            puzzlePlayId: $puzzlePlayId, cellState: $cellState,
            timeElapsedSeconds: $timeElapsedSeconds, progressState: $progressState
          }) { puzzlePlay { id progressState } errors }
        }
      GQL
    end

    it "persists progress_state verbatim", :aggregate_failures do
      progress = { "history" => { "undo" => [], "redo" => [] }, "elapsed" => 42 }
      result = execute_query(mutation_with_progress, context: auth_context(user),
        variables: { puzzlePlayId: play.id, cellState: cell_state, timeElapsedSeconds: 42, progressState: progress })
      expect(gql_data(result, "saveProgress", "puzzlePlay", "progressState")).to eq(progress)
      expect(play.reload.progress_state).to eq(progress)
    end
  end

  context "when the session is already solved" do
    let(:user) { create(:user) }
    let(:play) { create(:puzzle_play, :with_user, :solved, user: user) }

    it "does not overwrite the completed solve", :aggregate_failures do
      result = execute_query(mutation,
        variables: { puzzlePlayId: play.id, cellState: cell_state, timeElapsedSeconds: 999 },
        context: auth_context(user))
      expect(gql_data(result, "saveProgress", "errors")).to include("Session already solved")
      expect(play.reload.time_elapsed_seconds).to eq(300)
    end
  end
end
