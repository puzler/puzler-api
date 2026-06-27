require "rails_helper"

RSpec.describe "Mutation: updateOnboarding", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($onboardingSeen: JSON, $onboardingDisabled: Boolean) {
        updateOnboarding(input: { onboardingSeen: $onboardingSeen, onboardingDisabled: $onboardingDisabled }) {
          user { id onboardingSeen onboardingDisabled }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }

  def update_onboarding(vars)
    gql_data(execute_query(mutation, variables: vars, context: auth_context(user)), "updateOnboarding")
  end

  context "when authenticated" do
    it "persists the seen-tour map", :aggregate_failures do
      data = update_onboarding(onboardingSeen: { "player" => true })
      expect(data["errors"]).to be_empty
      expect(data["user"]["onboardingSeen"]).to eq({ "player" => true })
      expect(user.reload.onboarding_seen).to eq({ "player" => true })
    end

    it "persists the global disable toggle", :aggregate_failures do
      data = update_onboarding(onboardingDisabled: true)
      expect(data["user"]["onboardingDisabled"]).to be(true)
      expect(user.reload.onboarding_disabled).to be(true)
    end

    it "leaves the unspecified field untouched", :aggregate_failures do
      user.update!(onboarding_seen: { "home" => true })
      update_onboarding(onboardingDisabled: true)
      expect(user.reload.onboarding_seen).to eq({ "home" => true })
      expect(user.onboarding_disabled).to be(true)
    end
  end

  context "when viewed by another user" do
    let(:self_query) { "query($username: String!) { user(username: $username) { onboardingSeen onboardingDisabled } }" }

    it "hides the onboarding state from everyone but the owner", :aggregate_failures do
      user.update!(onboarding_seen: { "home" => true }, onboarding_disabled: true)
      data = gql_data(execute_query(self_query, variables: { username: user.username }, context: auth_context(create(:user))), "user")
      expect(data["onboardingSeen"]).to be_nil
      expect(data["onboardingDisabled"]).to be_nil
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { onboardingDisabled: true })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
