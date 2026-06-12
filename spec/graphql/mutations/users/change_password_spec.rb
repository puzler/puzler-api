require "rails_helper"

RSpec.describe "Mutation: changePassword", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($currentPassword: String, $newPassword: String!) {
        changePassword(input: { currentPassword: $currentPassword, newPassword: $newPassword }) {
          user { id passwordSet }
          token
          errors
        }
      }
    GQL
  end

  def change_password(user, **variables)
    execute_query(mutation, variables: variables, context: auth_context(user))
  end

  def decoded_jti(result)
    Warden::JWTAuth::TokenDecoder.new.call(gql_data(result, "changePassword", "token"))["jti"]
  end

  context "when the user has a password set" do
    let(:user) { create(:user, password: "password123") }

    it "changes the password with the correct current password", :aggregate_failures do
      result = change_password(user, currentPassword: "password123", newPassword: "newpassword456")

      expect(gql_data(result, "changePassword", "errors")).to be_empty
      expect(user.reload.valid_password?("newpassword456")).to be(true)
    end

    it "rotates the jti and returns a token valid for the new session", :aggregate_failures do
      old_jti = user.jti
      result = change_password(user, currentPassword: "password123", newPassword: "newpassword456")

      expect(user.reload.jti).not_to eq(old_jti)
      expect(decoded_jti(result)).to eq(user.jti)
    end

    it "rejects a wrong current password", :aggregate_failures do
      result = change_password(user, currentPassword: "wrong", newPassword: "newpassword456")

      expect(gql_data(result, "changePassword", "errors")).to eq([ "Current password is incorrect" ])
      expect(user.reload.valid_password?("password123")).to be(true)
    end

    it "requires the current password when omitted" do
      result = change_password(user, newPassword: "newpassword456")

      expect(gql_data(result, "changePassword", "errors")).to eq([ "Current password is incorrect" ])
    end

    it "returns validation errors for a too-short password" do
      result = change_password(user, currentPassword: "password123", newPassword: "x")

      expect(gql_data(result, "changePassword", "errors")).to include(a_string_matching(/Password/))
    end
  end

  context "when the user signed up via OAuth (no password set)" do
    let(:user) { create(:user).tap { |u| u.update_column(:password_set, false) } }

    it "sets a password without requiring the current one", :aggregate_failures do
      result = change_password(user, newPassword: "newpassword456")

      expect(gql_data(result, "changePassword", "errors")).to be_empty
      expect(gql_data(result, "changePassword", "user", "passwordSet")).to be(true)
      expect(user.reload.valid_password?("newpassword456")).to be(true)
    end
  end

  context "when unauthenticated" do
    it "returns an authentication error" do
      result = execute_query(mutation, variables: { newPassword: "newpassword456" })
      expect(gql_errors(result).first["message"]).to eq("Authentication required")
    end
  end
end
