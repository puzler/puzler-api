require "rails_helper"

RSpec.describe CompetitionScorer do
  let(:collection) do
    create(:collection, kind: :competition, time_limit_seconds: 1800,
      penalty_points: 5, bonus_points_per_minute: 2)
  end
  let(:run) do
    create(:competition_run, collection:, started_at: 30.minutes.ago, deadline: Time.current)
  end
  let(:puzzles) { Array.new(2) { create(:puzzle, status: :published, visibility: :public) } }

  before do
    puzzles.each_with_index do |puzzle, i|
      create(:collection_entry, collection:, puzzle:, position: i, points: 10 * (i + 1))
    end
  end

  def submit(puzzle, correct:, wrong_attempts: 0)
    create(:competition_submission, competition_run: run, puzzle:, correct:, wrong_attempts:)
  end

  def breakdown
    described_class.new(run.reload).breakdown
  end

  it "sums entry points for correct final submissions", :aggregate_failures do
    submit(puzzles[0], correct: true)
    submit(puzzles[1], correct: false)
    expect(breakdown).to include(base_points: 10, correct_count: 1)
  end

  it "charges blind penalties per incorrect FINAL submission only" do
    submit(puzzles[0], correct: true, wrong_attempts: 3) # resubmitting was free
    submit(puzzles[1], correct: false, wrong_attempts: 2)
    expect(breakdown[:penalty_points]).to eq(5)
  end

  it "charges instant penalties per wrong attempt" do
    collection.update!(submission_policy: :instant)
    submit(puzzles[0], correct: true, wrong_attempts: 3)
    expect(breakdown[:penalty_points]).to eq(15)
  end

  it "grants the bonus only on a full sweep, floored to whole minutes", :aggregate_failures do
    puzzles.each { |p| submit(p, correct: true) }
    run.update!(finished_at: run.deadline - 150) # 2.5 minutes early
    expect(breakdown[:bonus_points]).to eq(4)
    run.submissions.last.update!(correct: false)
    expect(breakdown[:bonus_points]).to eq(0)
  end

  it "clamps negative totals at zero by default, or allows them when the author opts out", :aggregate_failures do
    submit(puzzles[0], correct: false)
    submit(puzzles[1], correct: false)
    expect(breakdown[:total_points]).to eq(0)
    collection.update!(clamp_score_at_zero: false)
    expect(breakdown[:total_points]).to eq(-10)
  end

  it "reports scored time from start to effective end" do
    run.update!(finished_at: run.deadline - 300)
    expect(breakdown[:time_used_seconds]).to eq(1500)
  end
end
