require "rails_helper"

RSpec.describe "Mutation: updateProfile", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($username: String, $displayName: String, $bio: String) {
        updateProfile(input: { username: $username, displayName: $displayName, bio: $bio }) {
          user { id username displayName bio }
          errors
        }
      }
    GQL
  end

  context "when authenticated" do
    let(:user) { create(:user) }

    it "updates the user's profile", :aggregate_failures do
      result = execute_query(mutation, variables: { username: "newname", bio: "Hello world" }, context: auth_context(user))
      data = gql_data(result, "updateProfile")
      expect(data["errors"]).to be_empty
      expect(data["user"]["username"]).to eq("newname")
      expect(data["user"]["bio"]).to eq("Hello world")
    end

    it "updates the free-form display name", :aggregate_failures do
      result = execute_query(mutation, variables: { displayName: "Jane O'Doe Jr." }, context: auth_context(user))
      data = gql_data(result, "updateProfile")
      expect(data["errors"]).to be_empty
      expect(data["user"]["displayName"]).to eq("Jane O'Doe Jr.")
    end

    it "returns errors for an invalid username" do
      result = execute_query(mutation, variables: { username: "x" }, context: auth_context(user))
      expect(gql_data(result, "updateProfile", "errors")).not_to be_empty
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { username: "newname" })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
