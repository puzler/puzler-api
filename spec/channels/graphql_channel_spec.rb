require "rails_helper"

RSpec.describe GraphqlChannel, type: :channel do
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
end
