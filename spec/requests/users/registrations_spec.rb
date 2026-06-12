require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:params) do
    { user: { username: "newuser", email: "new@example.com", password: "password123" } }
  end

  describe "POST /users" do
    it "creates the user and dispatches a JWT", :aggregate_failures do
      post "/users", params: params, as: :json

      expect(response).to have_http_status(:created)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
    end

    it "persists the username and marks the password set", :aggregate_failures do
      post "/users", params: params, as: :json

      expect(User.find_by(email: "new@example.com")).to have_attributes(username: "newuser", password_set: true)
    end

    it "returns the serialized user" do
      post "/users", params: params, as: :json

      data = response.parsed_body["data"]["user"]
      expect(data).to include("username" => "newuser", "email" => "new@example.com", "password_set" => true)
    end

    it "returns validation errors for a bad username", :aggregate_failures do
      post "/users", params: { user: params[:user].merge(username: "x") }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to include(a_string_matching(/Username/))
    end

    it "rejects a duplicate email", :aggregate_failures do
      create(:user, email: "new@example.com")
      post "/users", params: params, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to include(a_string_matching(/Email/))
    end
  end
end
