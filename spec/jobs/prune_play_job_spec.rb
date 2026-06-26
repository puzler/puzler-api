require "rails_helper"

RSpec.describe PrunePlayJob do
  let(:guest_play) do
    create(:puzzle_play, user: nil, guest_token: "g_host").tap { |p| p.update_column(:updated_at, 1.hour.ago) }
  end

  it "reaps an idle, empty guest-hosted play" do
    id = guest_play.id # force creation before measuring the count change
    expect { described_class.perform_now(id) }.to change(PuzzlePlay, :count).by(-1)
  end

  it "spares a play that still has a live connection" do
    PresenceRegistry.add(guest_play.id, "conn-1")
    expect { described_class.perform_now(guest_play.id) }.not_to change(PuzzlePlay, :count)
  ensure
    PresenceRegistry.remove(guest_play.id, "conn-1")
  end

  it "spares a recently-updated (active) play" do
    guest_play.update_column(:updated_at, Time.current)
    expect { described_class.perform_now(guest_play.id) }.not_to change(PuzzlePlay, :count)
  end

  it "never reaps a user-owned play" do
    user_play = create(:puzzle_play, user: create(:user)).tap { |p| p.update_column(:updated_at, 1.hour.ago) }
    expect { described_class.perform_now(user_play.id) }.not_to change(PuzzlePlay, :count)
  end
end
