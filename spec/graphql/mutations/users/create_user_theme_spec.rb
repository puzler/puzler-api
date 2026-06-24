require "rails_helper"

RSpec.describe "Mutation: createUserTheme", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($uid: String!, $attrs: UserThemeAttrsInput!) {
        createUserTheme(input: { uid: $uid, attrs: $attrs }) {
          userTheme { id name basePresetId appearance constraints position }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }
  let(:rich_attrs) do
    {
      name: "Mine", basePresetId: "dark",
      appearance: { "chrome" => { "ink" => "#101010" }, "grid" => {} },
      constraints: { "german_whispers" => { "color" => "#ff0000" } }
    }
  end

  def create_theme(vars)
    gql_data(execute_query(mutation, variables: vars, context: auth_context(user)), "createUserTheme")
  end

  context "when authenticated" do
    it "creates a theme owned by the current user", :aggregate_failures do
      data = create_theme(uid: "t1", attrs: rich_attrs)
      expect(data["errors"]).to be_empty
      expect(data["userTheme"]).to include("id" => "t1", "basePresetId" => "dark", "position" => 0)
      expect(data["userTheme"]["appearance"]).to eq(rich_attrs[:appearance])
      expect(user.user_themes.count).to eq(1)
    end

    it "defaults the base preset to classic when omitted" do
      data = create_theme(uid: "t1", attrs: { name: "Plain" })
      expect(data["userTheme"]["basePresetId"]).to eq("classic")
    end

    it "appends each new theme after the last by position" do
      create(:user_theme, user:, position: 0)
      data = create_theme(uid: "t2", attrs: { name: "Second" })
      expect(data["userTheme"]["position"]).to eq(1)
    end

    it "rejects a duplicate uid for the same user", :aggregate_failures do
      create(:user_theme, user:, uid: "dup")
      data = create_theme(uid: "dup", attrs: { name: "Again" })
      expect(data["userTheme"]).to be_nil
      expect(data["errors"]).to be_present
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { uid: "t1", attrs: { name: "Mine" } })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
