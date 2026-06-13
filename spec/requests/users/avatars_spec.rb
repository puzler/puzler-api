require "rails_helper"

RSpec.describe "Avatars", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.generate_jwt}" } }

  # A real 800x600 PNG (see spec/fixtures/files/avatar.png) — the controller
  # decodes and re-encodes it, so fake bytes won't do.
  def image_upload(content_type: "image/png")
    fixture_file_upload("avatar.png", content_type)
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

  def undecodable_upload
    file = Tempfile.new([ "avatar", ".png" ])
    file.write("\x89PNG\r\n\x1a\nnot actually an image")
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png")
  end

  describe "PUT /me/avatar" do
    it "attaches a normalized avatar and returns its URL", :aggregate_failures do
      put "/me/avatar", params: { avatar: image_upload }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.avatar).to be_attached
      expect(response.parsed_body["data"]["user"]["avatar_url"]).to include("/rails/active_storage/")
    end

    it "downscales to <=512px and re-encodes to WebP", :aggregate_failures do
      put "/me/avatar", params: { avatar: image_upload }, headers: headers

      blob = user.reload.avatar.blob
      expect(blob.content_type).to eq("image/webp")

      stored = Vips::Image.new_from_buffer(user.avatar.download, "")
      expect([ stored.width, stored.height ].max).to be <= 512
    end

    it "accepts JPEG and WebP sources too" do
      put "/me/avatar", params: { avatar: image_upload(content_type: "image/jpeg") }, headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "rejects disallowed content types", :aggregate_failures do
      put "/me/avatar", params: { avatar: text_upload }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to eq([ "Avatar must be a PNG, JPEG, or WebP image" ])
      expect(user.reload.avatar).not_to be_attached
    end

    it "rejects files over 5MB before processing", :aggregate_failures do
      put "/me/avatar", params: { avatar: oversized_upload }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to eq([ "Avatar must be 5MB or smaller" ])
    end

    it "rejects an undecodable image gracefully", :aggregate_failures do
      put "/me/avatar", params: { avatar: undecodable_upload }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to eq([ "That image could not be processed" ])
      expect(user.reload.avatar).not_to be_attached
    end

    it "rejects a request without a file" do
      put "/me/avatar", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "requires authentication" do
      put "/me/avatar", params: { avatar: image_upload }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /me/avatar" do
    it "removes an attached avatar", :aggregate_failures do
      put "/me/avatar", params: { avatar: image_upload }, headers: headers
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
