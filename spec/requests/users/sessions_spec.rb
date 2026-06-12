require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, email: "user@example.com", password: "password123") }

  describe "POST /users/sign_in" do
    it "returns the user and dispatches a JWT", :aggregate_failures do
      post "/users/sign_in", params: { user: { email: "user@example.com", password: "password123" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(response.parsed_body["data"]["user"]["email"]).to eq("user@example.com")
    end

    it "rejects a wrong password", :aggregate_failures do
      post "/users/sign_in", params: { user: { email: "user@example.com", password: "wrong" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["Authorization"]).to be_nil
    end
  end

  describe "DELETE /users/sign_out" do
    let(:token) { user.generate_jwt }

    it "revokes the token", :aggregate_failures do
      delete "/users/sign_out", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)

      post "/graphql", params: { query: "{ me { username } }" },
                       headers: { "Authorization" => "Bearer #{token}" }, as: :json
      expect(response.parsed_body["data"]["me"]).to be_nil
    end

    it "rejects sign out without a token" do
      delete "/users/sign_out"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
