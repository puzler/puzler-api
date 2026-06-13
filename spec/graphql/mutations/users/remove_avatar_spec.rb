require "rails_helper"

RSpec.describe "Mutation: removeAvatar", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation {
        removeAvatar(input: {}) {
          user { id avatarUrl }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }

  def attach_avatar
    user.avatar.attach(
      io: Rails.root.join("spec/fixtures/files/avatar.png").open,
      filename: "avatar.png",
      content_type: "image/png"
    )
  end

  it "purges an attached avatar", :aggregate_failures do
    attach_avatar

    result = execute_query(mutation, context: auth_context(user))

    expect(gql_data(result, "removeAvatar", "errors")).to be_empty
    expect(user.reload.avatar).not_to be_attached
  end

  it "is a no-op when nothing is attached" do
    result = execute_query(mutation, context: auth_context(user))

    expect(gql_data(result, "removeAvatar", "errors")).to be_empty
  end

  it "requires authentication" do
    result = execute_query(mutation)
    expect(gql_errors(result).first["message"]).to eq("Authentication required")
  end
end
