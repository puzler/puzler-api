require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let!(:user) { create(:user, email: "user@example.com", password: "password123") }

  describe "POST /users/password" do
    it "emails reset instructions", :aggregate_failures do
      expect {
        post "/users/password", params: { user: { email: "user@example.com" } }, as: :json
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to have_http_status(:ok)
    end

    it "links to the frontend reset page", :aggregate_failures do
      post "/users/password", params: { user: { email: "user@example.com" } }, as: :json

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "user@example.com" ])
      expect(mail.body.encoded).to include("/reset-password?token=")
    end

    it "responds identically for an unknown email (paranoid mode)", :aggregate_failures do
      expect {
        post "/users/password", params: { user: { email: "nobody@example.com" } }, as: :json
      }.not_to change { ActionMailer::Base.deliveries.count }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to be_present
    end
  end

  describe "PUT /users/password" do
    let(:raw_token) { user.send_reset_password_instructions }

    def reset_password(token)
      put "/users/password", params: {
        user: { reset_password_token: token, password: "newpassword456", password_confirmation: "newpassword456" }
      }, as: :json
    end

    it "resets the password", :aggregate_failures do
      reset_password(raw_token)

      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?("newpassword456")).to be(true)
    end

    it "flips password_set for OAuth-created users" do
      user.update!(password_set: false)

      expect { reset_password(raw_token) }.to change { user.reload.password_set }.to(true)
    end

    it "revokes outstanding JWTs", :aggregate_failures do
      old_token = user.generate_jwt

      reset_password(raw_token)

      post "/graphql", params: { query: "{ me { username } }" },
                       headers: { "Authorization" => "Bearer #{old_token}" }, as: :json
      expect(response.parsed_body["data"]["me"]).to be_nil
    end

    it "rejects an invalid token", :aggregate_failures do
      reset_password("bogus")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to include(a_string_matching(/Reset password token/))
    end
  end
end
