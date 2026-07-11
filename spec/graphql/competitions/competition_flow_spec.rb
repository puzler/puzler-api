require "rails_helper"

RSpec.describe "Competition flow", type: :graphql do
  let(:author) { create(:user) }
  let(:solver) { create(:user) }
  let(:collection) do
    create(:collection, author:, visibility: :public, kind: :competition, time_limit_seconds: 1800)
  end
  let(:puzzle) do
    create(:puzzle, :published, author:, visibility: :public).tap do |p|
      create(:collection_entry, collection:, puzzle: p, points: 10)
    end
  end

  def start(context: auth_context(solver))
    m = "mutation($c: ID!) { startCompetitionRun(input: { collectionId: $c }) { run { id secondsRemaining deadline } errors } }"
    gql_data(execute_query(m, variables: { c: collection.id }, context:), "startCompetitionRun")
  end

  def submit(cell_state, context: auth_context(solver))
    m = <<~GQL
      mutation($c: ID!, $p: ID!, $s: JSON!) {
        submitCompetitionEntry(input: { collectionId: $c, puzzleId: $p, cellState: $s }) {
          accepted correct errors
        }
      }
    GQL
    gql_data(execute_query(m, variables: { c: collection.id, p: puzzle.id, s: cell_state }, context:),
      "submitCompetitionEntry")
  end

  def finish
    m = <<~GQL
      mutation($c: ID!) {
        finishCompetitionRun(input: { collectionId: $c }) {
          run { finalized totalPoints basePoints correctCount } errors
        }
      }
    GQL
    gql_data(execute_query(m, variables: { c: collection.id }, context: auth_context(solver)),
      "finishCompetitionRun")
  end

  describe "startCompetitionRun" do
    it "starts one run with a frozen deadline", :aggregate_failures do
      data = start
      expect(data["run"]["secondsRemaining"]).to be_between(1790, 1800)
      expect(start["run"]["id"]).to eq(data["run"]["id"]) # idempotent resume
    end

    def guest_start_errors
      gql_errors(execute_query(
        "mutation($c: ID!) { startCompetitionRun(input: { collectionId: $c }) { errors } }",
        variables: { c: collection.id }, context: {}
      ))
    end

    it "blocks authors and guests", :aggregate_failures do
      expect(start(context: auth_context(author))["errors"].first).to include("Authors cannot compete")
      expect(guest_start_errors.first["message"]).to eq("Authentication required")
    end

    it "refuses a second attempt after the run ends", :aggregate_failures do
      start
      CompetitionRun.find_by(collection:, user: solver).update!(finished_at: Time.current)
      expect(start["errors"].first).to include("already competed")
    end

    it "requires a time limit" do
      collection.update!(time_limit_seconds: nil)
      expect(start["errors"].first).to include('no time limit')
    end
  end

  describe "submitCompetitionEntry" do
    before { start }

    it "grades blind submissions without revealing the verdict, last write wins", :aggregate_failures do
      expect(submit(puzzle.solution)).to include("accepted" => true, "correct" => nil)
      expect(submit({ "r0c0" => 9 })).to include("accepted" => true, "correct" => nil)
      submission = CompetitionSubmission.find_by(puzzle:)
      expect(submission.correct).to be(false)
      expect(submission.wrong_attempts).to eq(1)
    end

    it "reveals the verdict under the instant policy" do
      collection.update!(submission_policy: :instant)
      expect(submit(puzzle.solution)["correct"]).to be(true)
    end

    it "rejects a second submission under the single policy", :aggregate_failures do
      collection.update!(submission_policy: :single)
      expect(submit(puzzle.solution)["accepted"]).to be(true)
      expect(submit(puzzle.solution)["errors"].first).to include('one submission')
    end

    it "rejects submissions after the deadline" do
      CompetitionRun.find_by(collection:, user: solver)
                    .update!(deadline: (CompetitionRun::GRACE_SECONDS + 2).seconds.ago)
      expect(submit(puzzle.solution)["errors"].first).to include('Time is up')
    end

    it "never creates a puzzle play (no solved-checkmark leak)" do
      expect { submit(puzzle.solution) }.not_to change(PuzzlePlay, :count)
    end
  end

  describe "entry point visibility" do
    let(:points_query) do
      "query($c: ID!) { collection(id: $c) { competitionConfig { totalPoints showEntryPoints } entries { points } } }"
    end

    def points_view(context:)
      gql_data(execute_query(points_query, variables: { c: collection.id }, context:), "collection")
    end

    def hide_points!
      puzzle
      collection.update!(show_entry_points: false)
    end

    it "hides per-puzzle points from solvers when the author opts out, keeping the total", :aggregate_failures do
      hide_points!
      solver_view = points_view(context: auth_context(solver))
      expect(solver_view["entries"].map { |e| e["points"] }).to eq([ nil ])
      expect(solver_view["competitionConfig"]).to include("totalPoints" => 10, "showEntryPoints" => false)
      expect(points_view(context: auth_context(author))["entries"].first["points"]).to eq(10)
    end

    it "shows per-puzzle points by default" do
      puzzle
      expect(points_view(context: auth_context(solver))["entries"].first["points"]).to eq(10)
    end
  end

  describe "finishCompetitionRun + leaderboard" do
    it "finalizes with a score breakdown", :aggregate_failures do
      start
      submit(puzzle.solution)
      run = finish["run"]
      expect(run).to include("finalized" => true, "totalPoints" => 10, "correctCount" => 1)
    end

    def leaderboard
      q = "query($c: ID!) { competitionLeaderboard(collectionId: $c) { rank username totalPoints } }"
      gql_data(execute_query(q, variables: { c: collection.id }, context: {}), "competitionLeaderboard")
    end

    def complete_run
      start
      submit(puzzle.solution)
      finish
    end

    it "ranks finalized runs and lazily finalizes expired ones", :aggregate_failures do
      complete_run
      rival = create(:competition_run, :expired, collection:)
      expect(leaderboard.map { |e| e["username"] }).to eq([ solver.username, rival.user.username ])
      expect(rival.reload.final?).to be(true)
    end
  end
end
