require "rails_helper"

RSpec.describe GraphqlChannel, type: :channel do
  let(:user) { create(:user) }

  before { stub_connection(current_user: user) }

  it "executes a plain query over the cable and replies once", :aggregate_failures do
    subscribe
    perform("execute", { "query" => "{ __typename }" })

    expect(transmissions.last["result"]["data"]["__typename"]).to eq("Query")
    expect(transmissions.last["more"]).to be(false)
  end

  it "subscribes and unsubscribes without error", :aggregate_failures do
    expect { subscribe }.not_to raise_error
    expect(subscription).to be_confirmed
    expect { unsubscribe }.not_to raise_error
  end

  describe "progressUpdated subscription authorization" do
    let(:sub_query) { "subscription($id: ID!) { progressUpdated(puzzlePlayId: $id) { puzzlePlay { id } } }" }

    it "registers the stream with no payload when the user owns the play" do
      play = create(:puzzle_play, user: user)
      subscribe
      perform("execute", "query" => sub_query, "variables" => { "id" => play.id.to_s })
      # subscribe returns :no_response — the initial frame carries no data, so the
      # channel transmits nothing (forwarding `{}` would choke Apollo's cache).
      expect(transmissions).to be_empty
    end

    it "transmits an authorization error for another user's play", :aggregate_failures do
      play = create(:puzzle_play, user: create(:user))
      subscribe
      perform("execute", "query" => sub_query, "variables" => { "id" => play.id.to_s })
      expect(transmissions.last["result"]["errors"].first["message"]).to eq("Not authorized")
    end
  end
end
