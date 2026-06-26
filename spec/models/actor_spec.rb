require "rails_helper"

RSpec.describe Actor do
  let(:user) { create(:user) }

  describe ".from_context" do
    it "builds a user actor when a current_user is present" do
      actor = described_class.from_context(current_user: user, guest_token: "ignored")
      expect(actor).to have_attributes(user?: true, guest?: false, user_id: user.id)
    end

    it "builds a guest actor from a token when there is no user", :aggregate_failures do
      actor = described_class.from_context(current_user: nil, guest_token: "g_abc")
      expect(actor.guest?).to be true
      expect(actor.guest_token).to eq("g_abc")
    end

    it "is nil when neither identity is present" do
      expect(described_class.from_context(current_user: nil, guest_token: "")).to be_nil
    end
  end

  describe "#key" do
    it "namespaces user and guest identities", :aggregate_failures do
      expect(described_class.new(user: user).key).to eq("user:#{user.id}")
      expect(described_class.new(guest_token: "g_abc").key).to eq("guest:g_abc")
    end
  end

  describe "attribute writers" do
    it "targets the guest columns for a guest actor", :aggregate_failures do
      actor = described_class.new(guest_token: "g_abc")
      expect(actor.owner_attrs).to eq(guest_token: "g_abc")
      expect(actor.token_created_by_attrs).to eq(created_by_guest_token: "g_abc")
    end
  end
end
