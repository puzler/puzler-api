require "rails_helper"

RSpec.describe Patreon::Token do
  let(:identity) do
    create(:user_oauth_identity, :patreon,
      access_token: "old-access", refresh_token: "old-refresh",
      expires_at: 20.days.from_now, scopes: "identity")
  end

  describe ".client_for" do
    it "returns a client without refreshing when the token is fresh", :aggregate_failures do
      expect(described_class.client_for(identity)).to be_a(Patreon::Client)
      expect(a_request(:post, described_class::TOKEN_ENDPOINT)).not_to have_been_made
    end

    it "refreshes proactively near expiry and persists the new pair", :aggregate_failures do
      identity.update!(expires_at: 1.hour.from_now)
      stub_patreon_token_refresh(access_token: "fresh", refresh_token: "fresh-r", scope: "identity")
      described_class.client_for(identity)

      expect(identity.reload).to have_attributes(access_token: "fresh", refresh_token: "fresh-r", scopes: "identity")
      expect(identity.expires_at).to be > 25.days.from_now
    end

    it "refreshes when no expiry was ever recorded (pre-feature identities)" do
      identity.update!(expires_at: nil)
      stub_patreon_token_refresh
      described_class.client_for(identity)
      expect(identity.reload.access_token).to eq("new-access")
    end

    it "raises RefreshFailed when Patreon rejects the refresh" do
      identity.update!(expires_at: nil)
      stub_patreon_token_refresh(status: 400)
      expect { described_class.client_for(identity) }.to raise_error(Patreon::Token::RefreshFailed)
    end

    it "raises RefreshFailed when no refresh token is stored" do
      identity.update!(expires_at: nil, refresh_token: nil)
      expect { described_class.client_for(identity) }.to raise_error(Patreon::Token::RefreshFailed, /no refresh token/)
    end
  end

  describe ".with_retry" do
    before do
      stub_request(:get, %r{/identity})
        .to_return({ status: 401, body: "{}" }, { status: 200, body: "{}", headers: { "Content-Type" => "application/json" } })
    end

    it "force-refreshes once on 401 and retries the block", :aggregate_failures do
      stub_patreon_token_refresh(access_token: "retried")

      result = described_class.with_retry(identity) { |client| client.identity_with_memberships }
      expect(result).to eq({})
      expect(identity.reload.access_token).to eq("retried")
    end

    it "raises RefreshFailed when the retried call is rejected again" do
      stub_request(:get, %r{/identity}).to_return(status: 401, body: "{}")
      stub_patreon_token_refresh

      expect {
        described_class.with_retry(identity) { |client| client.identity_with_memberships }
      }.to raise_error(Patreon::Token::RefreshFailed)
    end
    # (The second stub_request above replaces the before-block stub entirely.)
  end
end
