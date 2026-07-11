require "rails_helper"
require "omniauth/strategies/patreon"

RSpec.describe OmniAuth::Strategies::Patreon do
  # Build the redirect_uri the strategy would send to Patreon for a request-phase
  # URL. The request phase carries the connect_token as a query param so OmniAuth
  # can stash it in the session; that token must NOT leak into redirect_uri or
  # Patreon rejects the whole flow ("Redirect URI ... is not supported by client").
  def callback_url_for(url)
    env = Rack::MockRequest.env_for(url)
    strategy = described_class.new(->(_) { [ 200, {}, [] ] }, name: "patreon")
    strategy.instance_variable_set(:@env, env)
    strategy.callback_url
  end

  it "omits request-phase query params from redirect_uri" do
    url = "https://api.puzler.app/users/auth/patreon?connect_token=abc123"

    expect(callback_url_for(url)).to eq("https://api.puzler.app/users/auth/patreon/callback")
  end

  it "produces a clean callback even with no query params" do
    url = "https://api.puzler.app/users/auth/patreon"

    expect(callback_url_for(url)).to eq("https://api.puzler.app/users/auth/patreon/callback")
  end
end
