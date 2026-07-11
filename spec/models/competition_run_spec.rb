require "rails_helper"

RSpec.describe CompetitionRun do
  let(:run) { create(:competition_run) }

  it "is active until the deadline plus grace, then ends", :aggregate_failures do
    expect(run.active?).to be(true)
    run.update!(deadline: (CompetitionRun::GRACE_SECONDS - 1).seconds.ago)
    expect(run.active?).to be(true)
    run.update!(deadline: (CompetitionRun::GRACE_SECONDS + 1).seconds.ago)
    expect(run.ended?).to be(true)
  end

  it "ends immediately on an early finish" do
    run.update!(finished_at: Time.current)
    expect(run.ended?).to be(true)
  end

  it "clamps effective_end to the deadline" do
    run.update!(finished_at: run.deadline + 60)
    expect(run.effective_end).to eq(run.deadline)
  end

  it "finalizes idempotently with a frozen score", :aggregate_failures do
    run.update!(finished_at: Time.current)
    run.finalize!
    expect(run.final?).to be(true)
    expect { run.finalize! }.not_to change { run.reload.finalized_at }
  end

  it "allows one run per user per collection" do
    dup = build(:competition_run, collection: run.collection, user: run.user)
    expect { dup.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe ".active_for?" do
    let(:puzzle) { create(:puzzle, status: :published, visibility: :public) }

    before { create(:collection_entry, collection: run.collection, puzzle:) }

    it "is true only for the run's owner while active", :aggregate_failures do
      expect(described_class.active_for?(user: run.user, puzzle_id: puzzle.id)).to be(true)
      expect(described_class.active_for?(user: create(:user), puzzle_id: puzzle.id)).to be(false)
      expect(described_class.active_for?(user: nil, puzzle_id: puzzle.id)).to be(false)
    end

    it "is false once the run ends" do
      run.update!(finished_at: Time.current)
      expect(described_class.active_for?(user: run.user, puzzle_id: puzzle.id)).to be(false)
    end
  end
end
