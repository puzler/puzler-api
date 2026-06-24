require "rails_helper"

RSpec.describe "Mutation: updateThemePreferences", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($activeThemeId: String, $enableCustomStyles: Boolean) {
        updateThemePreferences(input: { activeThemeId: $activeThemeId, enableCustomStyles: $enableCustomStyles }) {
          user { id activeThemeId enableCustomStyles }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }

  def update_prefs(vars)
    gql_data(execute_query(mutation, variables: vars, context: auth_context(user)), "updateThemePreferences")
  end

  context "when authenticated" do
    it "updates the active theme and the custom-styles gate", :aggregate_failures do
      data = update_prefs(activeThemeId: "dark", enableCustomStyles: false)
      expect(data["errors"]).to be_empty
      expect(data["user"]).to include("activeThemeId" => "dark", "enableCustomStyles" => false)
      expect(user.reload).to have_attributes(active_theme_id: "dark", enable_custom_styles: false)
    end

    it "leaves the unspecified field untouched", :aggregate_failures do
      user.update!(active_theme_id: "dark", enable_custom_styles: false)
      update_prefs(enableCustomStyles: true)
      expect(user.reload).to have_attributes(active_theme_id: "dark", enable_custom_styles: true)
    end
  end

  context "when viewed by another user" do
    it "hides theme prefs from everyone but the owner", :aggregate_failures do
      user.update!(active_theme_id: "dark")
      query = "query($username: String!) { user(username: $username) { activeThemeId enableCustomStyles userThemes { id } } }"
      data = gql_data(execute_query(query, variables: { username: user.username }, context: auth_context(create(:user))), "user")
      expect(data).to include("activeThemeId" => nil, "enableCustomStyles" => nil, "userThemes" => nil)
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { activeThemeId: "dark" })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
