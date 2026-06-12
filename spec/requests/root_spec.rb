require "rails_helper"

RSpec.describe "Root", type: :request do
  describe "GET /" do
    it "responds with a hello message", :aggregate_failures do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to eq("Hello There")
    end
  end
end
