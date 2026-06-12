require "rails_helper"

RSpec.describe "Avatars", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.generate_jwt}" } }

  # Tiny valid PNG header is enough — the controller validates declared
  # content type and size, not image decodability.
  def png_upload
    file = Tempfile.new([ "avatar", ".png" ])
    file.write("\x89PNG\r\n\x1a\nfakeimagedata")
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png")
  end

  def text_upload
    file = Tempfile.new([ "avatar", ".txt" ])
    file.write("not an image")
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/plain")
  end

  def oversized_upload
    file = Tempfile.new([ "avatar", ".png" ])
    file.write("0" * (5.megabytes + 1))
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png")
  end

  describe "PUT /me/avatar" do
    it "attaches the avatar and returns the user with its URL", :aggregate_failures do
      put "/me/avatar", params: { avatar: png_upload }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.avatar).to be_attached
      expect(response.parsed_body["data"]["user"]["avatar_url"]).to include("/rails/active_storage/")
    end

    it "rejects disallowed content types", :aggregate_failures do
      put "/me/avatar", params: { avatar: text_upload }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to eq([ "Avatar must be a PNG, JPEG, or WebP image" ])
      expect(user.reload.avatar).not_to be_attached
    end

    it "rejects files over 5MB", :aggregate_failures do
      put "/me/avatar", params: { avatar: oversized_upload }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to eq([ "Avatar must be 5MB or smaller" ])
    end

    it "rejects a request without a file" do
      put "/me/avatar", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "requires authentication" do
      put "/me/avatar", params: { avatar: png_upload }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /me/avatar" do
    it "removes an attached avatar", :aggregate_failures do
      put "/me/avatar", params: { avatar: png_upload }, headers: headers
      delete "/me/avatar", headers: headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.avatar).not_to be_attached
      expect(response.parsed_body["data"]["user"]["avatar_url"]).to be_nil
    end

    it "is a no-op when nothing is attached" do
      delete "/me/avatar", headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "requires authentication" do
      delete "/me/avatar"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
