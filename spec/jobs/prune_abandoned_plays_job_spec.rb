require "rails_helper"

RSpec.describe PruneAbandonedPlaysJob do
  def guest_play(idle:)
    create(:puzzle_play, user: nil, guest_token: "g").tap { |p| p.update_column(:updated_at, idle) }
  end

  it "reaps an idle, empty guest-hosted play" do
    play = guest_play(idle: 2.hours.ago)
    expect { described_class.perform_now }.to change { PuzzlePlay.exists?(play.id) }.to(false)
  end

  it "spares a recently-active play" do
    guest_play(idle: 10.minutes.ago)
    expect { described_class.perform_now }.not_to change(PuzzlePlay, :count)
  end

  it "spares an idle play that still has a live connection" do
    play = guest_play(idle: 2.hours.ago)
    PresenceRegistry.add(play.id, "conn-1")
    expect { described_class.perform_now }.not_to change(PuzzlePlay, :count)
  end

  it "never reaps a user-owned play" do
    create(:puzzle_play, user: create(:user)).tap { |p| p.update_column(:updated_at, 2.hours.ago) }
    expect { described_class.perform_now }.not_to change(PuzzlePlay, :count)
  end
end
