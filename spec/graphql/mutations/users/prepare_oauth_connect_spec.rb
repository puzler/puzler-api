require "rails_helper"

RSpec.describe "Mutation: prepareOauthConnect", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($provider: String!) {
        prepareOauthConnect(input: { provider: $provider }) {
          url
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }

  it "returns an OAuth URL with a connect token for the current user", :aggregate_failures do
    result = execute_query(mutation, variables: { provider: "google" }, context: auth_context(user))

    url = gql_data(result, "prepareOauthConnect", "url")
    expect(url).to start_with("http://localhost:3000/users/auth/google_oauth2?connect_token=")

    raw_token = Rack::Utils.parse_query(URI.parse(url).query)["connect_token"]
    expect(Rails.application.message_verifier(:oauth_connect).verified(raw_token)).to eq(user.id)
  end

  it "maps patreon to its route" do
    result = execute_query(mutation, variables: { provider: "patreon" }, context: auth_context(user))

    expect(gql_data(result, "prepareOauthConnect", "url")).to include("/users/auth/patreon?connect_token=")
  end

  it "rejects an unknown provider", :aggregate_failures do
    result = execute_query(mutation, variables: { provider: "github" }, context: auth_context(user))

    data = gql_data(result, "prepareOauthConnect")
    expect(data["url"]).to be_nil
    expect(data["errors"]).to eq([ "Unknown provider: github" ])
  end

  it "requires authentication" do
    result = execute_query(mutation, variables: { provider: "google" })
    expect(gql_errors(result).first["message"]).to eq("Authentication required")
  end
end
