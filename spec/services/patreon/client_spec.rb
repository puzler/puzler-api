require "rails_helper"

RSpec.describe Patreon::Client do
  subject(:client) { described_class.new("token-123") }

  describe "#identity_with_memberships" do
    # v2 returns NO attributes unless every field is requested explicitly.
    def explicit_fields?(req)
      query = Rack::Utils.parse_query(URI(req.uri).query)
      query["fields[member]"].include?("patron_status") &&
        query["fields[member]"].include?("pledge_relationship_start") &&
        query["include"].include?("memberships.currently_entitled_tiers") &&
        req.headers["Authorization"] == "Bearer token-123"
    end

    it "requests explicit member/campaign/tier fields" do
      stub = stub_patreon_identity_memberships([])
      client.identity_with_memberships
      expect(stub.with { |req| explicit_fields?(req) }).to have_been_requested
    end
  end

  describe "#campaign_members" do
    it "returns the parsed body plus the next cursor", :aggregate_failures do
      stub_patreon_campaign_members("camp-1", [ { member_id: "m1", user_id: "u1" } ], next_cursor: "abc")

      body, cursor = client.campaign_members("camp-1")
      expect(body["data"].first["id"]).to eq("m1")
      expect(cursor).to eq("abc")
    end

    it "passes the cursor through on subsequent pages" do
      stub_patreon_campaign_members("camp-1", [], cursor: "abc")
      _body, cursor = client.campaign_members("camp-1", cursor: "abc")
      expect(cursor).to be_nil
    end
  end

  describe "error mapping" do
    it "raises Unauthorized on 401" do
      stub_request(:get, %r{/identity}).to_return(status: 401, body: "{}")
      expect { client.identity_with_memberships }.to raise_error(Patreon::Client::Unauthorized)
    end

    it "raises RateLimited on 429" do
      stub_request(:get, %r{/identity}).to_return(status: 429, body: "{}")
      expect { client.identity_with_memberships }.to raise_error(Patreon::Client::RateLimited)
    end

    it "raises NotFound on 404" do
      stub_request(:get, %r{/campaigns/gone\?}).to_return(status: 404, body: "{}")
      expect { client.campaign_with_tiers("gone") }.to raise_error(Patreon::Client::NotFound)
    end

    it "raises Error on unparseable success bodies" do
      stub_request(:get, %r{/identity}).to_return(status: 200, body: "not json")
      expect { client.identity_with_memberships }.to raise_error(Patreon::Client::Error, /unparseable/)
    end

    it "wraps network failures in Error" do
      stub_request(:get, %r{/identity}).to_timeout
      expect { client.identity_with_memberships }.to raise_error(Patreon::Client::Error)
    end
  end

  describe "#create_webhook" do
    it "posts the campaign relationship and returns the secret payload", :aggregate_failures do
      stub_patreon_webhook_create(webhook_id: "wh-9", secret: "s3cret")

      body = client.create_webhook("camp-1", uri: "https://api.test/webhooks/patreon/1",
                                             triggers: %w[members:create members:update members:delete])
      expect(body.dig("data", "id")).to eq("wh-9")
      expect(body.dig("data", "attributes", "secret")).to eq("s3cret")
    end
  end
end
