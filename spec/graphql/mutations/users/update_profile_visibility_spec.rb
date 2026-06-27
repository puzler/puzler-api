require "rails_helper"

RSpec.describe "Mutation: updateProfileVisibility", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($attrs: ProfileVisibilityInput!) {
        updateProfileVisibility(input: { attrs: $attrs }) {
          user { id profileVisibility { solveHistory stats favorites subscriptions activity } }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }

  def update_visibility(attrs)
    gql_data(execute_query(mutation, variables: { attrs: }, context: auth_context(user)), "updateProfileVisibility")
  end

  context "when authenticated" do
    it "updates the solve-history level and the section toggles", :aggregate_failures do
      data = update_visibility(solveHistoryVisibility: "DETAILED", showFavorites: true, showActivity: true)
      expect(data["errors"]).to be_empty
      expect(data["user"]["profileVisibility"]).to include("solveHistory" => "DETAILED", "favorites" => true, "activity" => true)
      expect(user.reload).to have_attributes(solve_history_visibility: "detailed", show_favorites: true, show_activity: true)
    end

    it "leaves unspecified preferences untouched", :aggregate_failures do
      user.update!(solve_history_visibility: :detailed, show_stats: false)
      update_visibility(showFavorites: true)
      expect(user.reload).to have_attributes(solve_history_visibility: "detailed", show_stats: false, show_favorites: true)
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { attrs: { showStats: false } })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
