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

    it "relays a server-stamped cell batch to the play" do
      subscribe(play_id: play.id, display_name: "Owner")
      states = { "r0c0" => { "value" => 5 } }
      expect { perform(:cells, "states" => states) }
        .to have_broadcasted_to(play).with(hash_including("type" => "cells", "states" => states, "actorId" => "user:#{owner.id}"))
    end

    it "drops a cell relay that is not a hash or is oversized", :aggregate_failures do
      subscribe(play_id: play.id, display_name: "Owner")
      expect { perform(:cells, "states" => %w[not a hash]) }.not_to have_broadcasted_to(play)
      oversized = (0..PresenceChannel::MAX_RELAY_CELLS).to_h { |i| [ "r#{i}c0", { "value" => 1 } ] }
      expect { perform(:cells, "states" => oversized) }.not_to have_broadcasted_to(play)
    end

    it "broadcasts a stamped catch-up request" do
      subscribe(play_id: play.id, display_name: "Owner")
      expect { perform(:request_cells) }
        .to have_broadcasted_to(play).with(hash_including("type" => "request_cells", "actorId" => "user:#{owner.id}"))
    end
  end

  context "when a participant is kicked after subscribing" do
    let(:guest_token) { "g_kicked" }

    before do
      stub_connection(current_user: nil, guest_token: guest_token)
      create(:puzzle_play_participant, :guest, puzzle_play: play, guest_token: guest_token)
      subscribe(play_id: play.id, display_name: "Guest")
    end

    it "stops relaying their cursor and cells once access is revoked", :aggregate_failures do
      play.participants.where(guest_token: guest_token).destroy_all
      expect { perform(:cursor, "cells" => %w[r0c0]) }.not_to have_broadcasted_to(play)
      expect { perform(:cells, "states" => { "r0c0" => { "value" => 1 } }) }.not_to have_broadcasted_to(play)
      expect { perform(:request_cells) }.not_to have_broadcasted_to(play)
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
