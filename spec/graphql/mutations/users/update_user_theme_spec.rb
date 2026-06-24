require "rails_helper"

RSpec.describe "Mutation: updateUserTheme", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($uid: String!, $attrs: UserThemeAttrsInput!) {
        updateUserTheme(input: { uid: $uid, attrs: $attrs }) {
          userTheme { id name constraints }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }
  let!(:theme) { create(:user_theme, user:, uid: "t1", name: "Old") }

  def update_theme(vars)
    gql_data(execute_query(mutation, variables: vars, context: auth_context(user)), "updateUserTheme")
  end

  it "updates fields on the user's own theme", :aggregate_failures do
    data = update_theme(uid: "t1", attrs: { name: "New", constraints: { "renban" => { "strokeWidth" => 12 } } })
    expect(data["errors"]).to be_empty
    expect(data["userTheme"]["name"]).to eq("New")
    expect(theme.reload.constraints).to eq({ "renban" => { "strokeWidth" => 12 } })
  end

  it "is scoped to the current user (won't edit another user's same-uid theme)", :aggregate_failures do
    other = create(:user_theme, uid: "t1", name: "Theirs")
    update_theme(uid: "t1", attrs: { name: "Hacked" })
    expect(other.reload.name).to eq("Theirs")
    expect(theme.reload.name).to eq("Hacked")
  end

  it "returns an error for an unknown uid", :aggregate_failures do
    data = update_theme(uid: "ghost", attrs: { name: "X" })
    expect(data["userTheme"]).to be_nil
    expect(data["errors"]).to be_present
  end
end
