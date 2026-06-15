require "rails_helper"

RSpec.describe "Mutation: updatePlayerPrefs", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($playerSettings: JSON, $colorPalette: JSON) {
        updatePlayerPrefs(input: { playerSettings: $playerSettings, colorPalette: $colorPalette }) {
          user { id playerSettings colorPalette }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }

  def update_prefs(vars)
    gql_data(execute_query(mutation, variables: vars, context: auth_context(user)), "updatePlayerPrefs")
  end

  context "when authenticated" do
    it "persists player settings", :aggregate_failures do
      data = update_prefs(playerSettings: { "hideTimer" => true })
      expect(data["errors"]).to be_empty
      expect(data["user"]["playerSettings"]).to eq({ "hideTimer" => true })
      expect(user.reload.player_settings).to eq({ "hideTimer" => true })
    end

    it "persists the color palette", :aggregate_failures do
      palette = { "colors" => { "1" => "rgb(180, 128, 241)" }, "pages" => [ [ "1" ] ] }
      data = update_prefs(colorPalette: palette)
      expect(data["user"]["colorPalette"]).to eq(palette)
      expect(user.reload.color_palette).to eq(palette)
    end

    it "leaves the unspecified field untouched", :aggregate_failures do
      user.update!(player_settings: { "hideTimer" => true })
      update_prefs(colorPalette: { "pages" => [ [ "1" ] ] })
      expect(user.reload.player_settings).to eq({ "hideTimer" => true })
      expect(user.color_palette).to eq({ "pages" => [ [ "1" ] ] })
    end
  end

  context "when viewed by another user" do
    let(:self_query) { "query($username: String!) { user(username: $username) { playerSettings colorPalette } }" }

    it "hides the prefs from everyone but the owner", :aggregate_failures do
      user.update!(player_settings: { "hideTimer" => true })
      data = gql_data(execute_query(self_query, variables: { username: user.username }, context: auth_context(create(:user))), "user")
      expect(data["playerSettings"]).to be_nil
      expect(data["colorPalette"]).to be_nil
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { playerSettings: { "hideTimer" => true } })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
