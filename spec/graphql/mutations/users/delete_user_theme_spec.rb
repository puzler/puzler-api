require "rails_helper"

RSpec.describe "Mutation: deleteUserTheme", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($uid: String!) {
        deleteUserTheme(input: { uid: $uid }) { deletedId errors }
      }
    GQL
  end

  let(:user) { create(:user) }
  let!(:theme) { create(:user_theme, user:, uid: "t1") }

  def delete_theme(vars)
    gql_data(execute_query(mutation, variables: vars, context: auth_context(user)), "deleteUserTheme")
  end

  it "deletes the user's own theme", :aggregate_failures do
    data = delete_theme(uid: "t1")
    expect(data["deletedId"]).to eq("t1")
    expect(data["errors"]).to be_empty
    expect(UserTheme.exists?(theme.id)).to be(false)
  end

  it "is scoped to the current user (won't delete another user's same-uid theme)", :aggregate_failures do
    other = create(:user_theme, uid: "t1")
    delete_theme(uid: "t1")
    expect(UserTheme.exists?(other.id)).to be(true)
    expect(UserTheme.exists?(theme.id)).to be(false)
  end

  it "returns an error for an unknown uid", :aggregate_failures do
    data = delete_theme(uid: "ghost")
    expect(data["deletedId"]).to be_nil
    expect(data["errors"]).to be_present
  end
end
