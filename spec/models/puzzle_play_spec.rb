require "rails_helper"

RSpec.describe PuzzlePlay do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }
  let(:play)  { create(:puzzle_play, user: owner) }

  def actor_for(user: nil, guest_token: nil)
    Actor.from_context(current_user: user, guest_token: guest_token)
  end

  describe "#accessible_by?" do
    it "grants the user owner" do
      expect(play.accessible_by?(actor_for(user: owner))).to be true
    end

    it "denies a stranger" do
      expect(play.accessible_by?(actor_for(user: other))).to be false
    end

    it "grants a user participant" do
      create(:puzzle_play_participant, puzzle_play: play, user: other)
      expect(play.accessible_by?(actor_for(user: other))).to be true
    end

    it "grants a guest participant of a user-owned play" do
      create(:puzzle_play_participant, :guest, puzzle_play: play, guest_token: "g_1")
      expect(play.accessible_by?(actor_for(guest_token: "g_1"))).to be true
    end

    it "denies a guest who has not joined" do
      expect(play.accessible_by?(actor_for(guest_token: "g_other"))).to be false
    end
  end

  describe "guest-hosted plays" do
    let(:guest_play) { create(:puzzle_play, user: nil, guest_token: "g_host") }

    it "is owned by its guest token and reported as guest_hosted", :aggregate_failures do
      expect(guest_play.owned_by?(actor_for(guest_token: "g_host"))).to be true
      expect(guest_play.guest_hosted?).to be true
      expect(described_class.guest_hosted).to include(guest_play)
    end

    it "lets a user participant access a guest-owned play" do
      create(:puzzle_play_participant, puzzle_play: guest_play, user: other)
      expect(guest_play.accessible_by?(actor_for(user: other))).to be true
    end
  end

  describe "#blocked?" do
    it "is true for a blocked guest" do
      play.blocked_actors.create!(guest_token: "g_blocked")
      expect(play.blocked?(actor_for(guest_token: "g_blocked"))).to be true
    end
  end
end
