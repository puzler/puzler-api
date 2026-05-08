require "rails_helper"

RSpec.describe "Queries: users", type: :graphql do
  describe "me" do
    let(:query) do
      <<~GQL
        query { me { id username email role } }
      GQL
    end

    context "when authenticated" do
      let(:user) { create(:user) }

      it "returns the current user" do
        result = execute_query(query, context: auth_context(user))
        expect(gql_data(result, "me")).to include("id" => user.id.to_s, "username" => user.username, "email" => user.email)
      end
    end

    context "when unauthenticated" do
      it "returns nil" do
        result = execute_query(query)
        expect(gql_data(result, "me")).to be_nil
      end
    end
  end

  describe "user(username:)" do
    let(:query) do
      <<~GQL
        query($username: String!) {
          user(username: $username) { id username }
        }
      GQL
    end

    let(:user) { create(:user) }

    it "returns the user by username" do
      result = execute_query(query, variables: { username: user.username })
      expect(gql_data(result, "user", "username")).to eq(user.username)
    end

    it "returns nil for an unknown username" do
      result = execute_query(query, variables: { username: "nobody" })
      expect(gql_data(result, "user")).to be_nil
    end
  end
end
