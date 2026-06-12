require "rails_helper"

RSpec.describe User, type: :model do
  describe "#generate_jwt" do
    it "produces a token that decodes back to the user", :aggregate_failures do
      user = create(:user)
      payload = Warden::JWTAuth::TokenDecoder.new.call(user.generate_jwt)

      expect(payload["sub"]).to eq(user.id.to_s)
      expect(payload["jti"]).to eq(user.jti)
    end
  end

  describe "password change side effects" do
    let(:user) { create(:user) }

    it "marks password_set and rotates jti when the password changes", :aggregate_failures do
      user.update_column(:password_set, false)
      old_jti = user.jti

      user.update!(password: "anotherpassword")

      expect(user.password_set).to be(true)
      expect(user.jti).not_to eq(old_jti)
    end

    it "leaves jti alone for unrelated updates" do
      expect { user.update!(bio: "hello") }.not_to change { user.reload.jti }
    end
  end

  describe "#resolved_avatar_url" do
    let(:user) { create(:user, avatar_url: "https://example.com/oauth.jpg") }

    it "falls back to the avatar_url column" do
      expect(user.resolved_avatar_url).to eq("https://example.com/oauth.jpg")
    end

    it "prefers an attached avatar" do
      user.avatar.attach(io: StringIO.new("fake image data"), filename: "avatar.png", content_type: "image/png")

      expect(user.resolved_avatar_url).to include("/rails/active_storage/blobs/")
    end
  end
end
