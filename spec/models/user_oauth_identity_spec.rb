require "rails_helper"

RSpec.describe UserOauthIdentity, type: :model do
  describe "token encryption" do
    let(:identity) do
      create(:user_oauth_identity, access_token: "plain-access", refresh_token: "plain-refresh")
    end

    def raw_columns
      described_class.connection.select_one(
        "SELECT access_token, refresh_token FROM user_oauth_identities WHERE id = #{identity.id}"
      )
    end

    it "stores tokens ciphered at rest", :aggregate_failures do
      expect(raw_columns["access_token"]).not_to include("plain-access")
      expect(raw_columns["refresh_token"]).not_to include("plain-refresh")
    end

    it "decrypts tokens on read", :aggregate_failures do
      expect(identity.reload.access_token).to eq("plain-access")
      expect(identity.refresh_token).to eq("plain-refresh")
    end
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:provider).in_array(%w[google patreon]) }
  end
end
