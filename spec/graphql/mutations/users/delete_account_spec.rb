require "rails_helper"

RSpec.describe "Mutation: deleteAccount", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($currentPassword: String, $confirmation: String) {
        deleteAccount(input: { currentPassword: $currentPassword, confirmation: $confirmation }) {
          success
          errors
        }
      }
    GQL
  end

  def delete_account(user, **variables)
    execute_query(mutation, variables: variables, context: auth_context(user))
  end

  context "when the user has a password" do
    let!(:user) { create(:user, password: "password123") }

    it "deletes the account with the correct password", :aggregate_failures do
      result = delete_account(user, currentPassword: "password123")

      expect(gql_data(result, "deleteAccount", "success")).to be(true)
      expect(User.exists?(user.id)).to be(false)
    end

    it "rejects a wrong password", :aggregate_failures do
      result = delete_account(user, currentPassword: "wrong")

      expect(gql_data(result, "deleteAccount", "errors")).to eq([ "Current password is incorrect" ])
      expect(User.exists?(user.id)).to be(true)
    end

    it "cascades to all owned data", :aggregate_failures do
      identity = create(:user_oauth_identity, user: user)
      puzzle = create(:puzzle, author: user)

      delete_account(user, currentPassword: "password123")

      expect(UserOauthIdentity.exists?(identity.id)).to be(false)
      expect(Puzzle.exists?(puzzle.id)).to be(false)
    end
  end

  context "when the user is OAuth-only (no password set)" do
    let!(:user) { create(:user).tap { |u| u.update_column(:password_set, false) } }

    it "deletes with typed confirmation", :aggregate_failures do
      result = delete_account(user, confirmation: "DELETE")

      expect(gql_data(result, "deleteAccount", "success")).to be(true)
      expect(User.exists?(user.id)).to be(false)
    end

    it "rejects without the confirmation", :aggregate_failures do
      result = delete_account(user, confirmation: "nope")

      expect(gql_data(result, "deleteAccount", "errors")).to eq([ 'Type "DELETE" to confirm' ])
      expect(User.exists?(user.id)).to be(true)
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { confirmation: "DELETE" })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
