require "rails_helper"

RSpec.describe User, type: :model do
  describe "display_name" do
    it "defaults to the username when blank on create" do
      user = create(:user, username: "alice", display_name: nil)
      expect(user.display_name).to eq("alice")
    end

    it "allows spaces and punctuation, and is not unique", :aggregate_failures do
      create(:user, display_name: "Jane O'Doe-Smith Jr.")
      twin = build(:user, display_name: "Jane O'Doe-Smith Jr.")
      expect(twin).to be_valid
    end

    it "strips surrounding whitespace" do
      user = create(:user, display_name: "  Spacey  ")
      expect(user.display_name).to eq("Spacey")
    end

    it "is capped at 50 characters" do
      expect(build(:user, display_name: "a" * 51)).not_to be_valid
    end

    it "cannot be blanked once set (no create-time fallback on update)" do
      user = create(:user, display_name: "Original")
      user.display_name = "  "
      expect(user).not_to be_valid
    end
  end

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

    it "prefers an attached avatar, served as the normalized variant" do
      user.avatar.attach(io: StringIO.new("fake image data"), filename: "avatar.png", content_type: "image/png")

      expect(user.resolved_avatar_url).to include("/rails/active_storage/representations/")
    end
  end

  describe "#recompute_setter_stats!" do
    let(:setter) { create(:user) }

    # Build a setter whose published puzzles carry the given ratings, newest
    # first (index 0 = most recent), then recompute and return them.
    def setter_with(ratings)
      user = create(:user)
      ratings.each_with_index { |r, i| create(:puzzle, :published, author: user, avg_rating: r, published_at: i.days.ago) }
      user.tap(&:recompute_setter_stats!)
    end

    it "stays new with no published puzzles", :aggregate_failures do
      setter.recompute_setter_stats!
      expect(setter.setter_score).to eq(0.0)
      expect(setter).to be_setter_new
    end

    it "reaches experienced with enough well-rated puzzles" do
      expect(setter_with([ 4.5, 4.5, 4.5, 4.5, 4.5 ])).to be_setter_experienced
    end

    it "weights recent ratings more than old ones (same ratings, opposite recency)" do
      expect(setter_with([ 5, 5, 5, 2 ]).setter_score).to be > setter_with([ 2, 5, 5, 5 ]).setter_score
    end
  end
end
