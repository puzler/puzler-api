require "rails_helper"

RSpec.describe "Mutation: disconnectOauthProvider", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($provider: String!) {
        disconnectOauthProvider(input: { provider: $provider }) {
          user { id oauthConnections { provider } }
          errors
        }
      }
    GQL
  end

  context "when the user has a password" do
    let(:user) { create(:user) }

    before { create(:user_oauth_identity, user: user, provider: "google") }

    it "disconnects the provider", :aggregate_failures do
      result = execute_query(mutation, variables: { provider: "google" }, context: auth_context(user))

      data = gql_data(result, "disconnectOauthProvider")
      expect(data["errors"]).to be_empty
      expect(data["user"]["oauthConnections"]).to be_empty
      expect(user.oauth_identities.count).to eq(0)
    end

    it "errors when the provider isn't connected" do
      result = execute_query(mutation, variables: { provider: "patreon" }, context: auth_context(user))

      expect(gql_data(result, "disconnectOauthProvider", "errors")).to eq([ "Patreon is not connected" ])
    end
  end

  context "when the identity is the last sign-in method" do
    let(:user) { create(:user).tap { |u| u.update_column(:password_set, false) } }

    before { create(:user_oauth_identity, user: user, provider: "google") }

    it "refuses to disconnect", :aggregate_failures do
      result = execute_query(mutation, variables: { provider: "google" }, context: auth_context(user))

      expect(gql_data(result, "disconnectOauthProvider", "errors"))
        .to eq([ "You can't remove your last way to sign in. Set a password first." ])
      expect(user.oauth_identities.count).to eq(1)
    end

    it "allows disconnecting when another identity remains", :aggregate_failures do
      create(:user_oauth_identity, :patreon, user: user)

      result = execute_query(mutation, variables: { provider: "google" }, context: auth_context(user))

      expect(gql_data(result, "disconnectOauthProvider", "errors")).to be_empty
      expect(user.oauth_identities.pluck(:provider)).to eq([ "patreon" ])
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { provider: "google" })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
