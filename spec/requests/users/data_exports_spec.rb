require "rails_helper"

RSpec.describe "Data exports", type: :request do
  describe "GET /me/export" do
    let(:user) { create(:user, bio: "I like puzzles") }
    let(:headers) { { "Authorization" => "Bearer #{user.generate_jwt}" } }

    before { create(:user_oauth_identity, user: user, access_token: "secret-token") }

    it "returns a JSON attachment", :aggregate_failures do
      get "/me/export", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include("puzler-data-#{user.username}")
    end

    it "includes the user's data", :aggregate_failures do
      get "/me/export", headers: headers

      data = response.parsed_body
      expect(data["profile"]).to include("email" => user.email, "username" => user.username, "bio" => "I like puzzles")
      expect(data["oauth_connections"].first).to include("provider" => "google")
    end

    it "never includes OAuth tokens", :aggregate_failures do
      get "/me/export", headers: headers

      expect(response.body).not_to include("secret-token")
      expect(response.body).not_to include("access_token")
      expect(response.body).not_to include("refresh_token")
    end

    it "requires authentication" do
      get "/me/export"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
