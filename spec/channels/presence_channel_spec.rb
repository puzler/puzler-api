require "rails_helper"

RSpec.describe PresenceChannel, type: :channel do
  let(:owner) { create(:user) }
  let(:play) { create(:puzzle_play, user: owner) }

  context "when the user owns the play" do
    before { stub_connection(current_user: owner, guest_token: nil) }

    it "confirms and streams for an accessible play", :aggregate_failures do
      subscribe(play_id: play.id, display_name: "Owner")
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(play)
    end

    it "rejects a play the actor cannot access" do
      other = create(:puzzle_play, user: create(:user))
      subscribe(play_id: other.id)
      expect(subscription).to be_rejected
    end

    it "rejects a missing play" do
      subscribe(play_id: 0)
      expect(subscription).to be_rejected
    end

    it "broadcasts a server-stamped cursor to the play" do
      subscribe(play_id: play.id, display_name: "Owner")
      expect { perform(:cursor, "cells" => %w[r0c0 r0c1]) }
        .to have_broadcasted_to(play).with(hash_including("type" => "cursor", "actorId" => "user:#{owner.id}", "isHost" => true))
    end
  end

  context "when the actor is a guest" do
    before { stub_connection(current_user: nil, guest_token: "g_join") }

    it "confirms once the guest has joined" do
      create(:puzzle_play_participant, :guest, puzzle_play: play, guest_token: "g_join")
      subscribe(play_id: play.id)
      expect(subscription).to be_confirmed
    end

    it "rejects a guest who has not joined" do
      subscribe(play_id: play.id)
      expect(subscription).to be_rejected
    end
  end
end
