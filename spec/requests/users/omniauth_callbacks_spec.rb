require "rails_helper"

RSpec.describe "OmniAuth callbacks", type: :request do
  let(:frontend) { "http://localhost:5173" }

  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.mock_auth[:patreon] = nil
    Rails.application.env_config.delete("omniauth.auth")
    Rails.application.env_config.delete("omniauth.params")
  end

  def mock_google(uid: "google-uid-1", email: "oauth@example.com", verified: true)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, name: "OAuth User", image: "https://example.com/pic.jpg" },
      credentials: { token: "tok", refresh_token: "refresh" },
      extra: { id_info: { "email_verified" => verified } }
    )
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  def mock_patreon(uid: "patreon-uid-1", email: "patron@example.com")
    OmniAuth.config.mock_auth[:patreon] = OmniAuth::AuthHash.new(
      provider: "patreon",
      uid: uid,
      info: { email: email, name: "Patron", image: nil },
      credentials: { token: "tok", refresh_token: "refresh" }
    )
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:patreon]
  end

  def connect_token_for(user, expires_in: 5.minutes)
    Rails.application.message_verifier(:oauth_connect).generate(user.id, expires_in: expires_in)
  end

  describe "fresh signup" do
    it "creates a user with profile info from the provider", :aggregate_failures do
      mock_google

      expect { get "/users/auth/google_oauth2/callback" }.to change(User, :count).by(1)

      user = User.order(:id).last
      expect(user).to have_attributes(email: "oauth@example.com", password_set: false, avatar_url: "https://example.com/pic.jpg")
      expect(user.oauth_identities.pluck(:provider, :uid)).to eq([ [ "google", "google-uid-1" ] ])
    end

    it "redirects to the frontend with a token" do
      mock_google

      get "/users/auth/google_oauth2/callback"

      expect(response).to redirect_to(%r{\A#{frontend}/auth/callback/google\?token=})
    end

    it "logs in an existing identity without creating a user", :aggregate_failures do
      identity = create(:user_oauth_identity, uid: "google-uid-1")
      mock_google

      expect { get "/users/auth/google_oauth2/callback" }.not_to change(User, :count)

      expect(identity.reload.access_token).to eq("tok")
      expect(response).to redirect_to(%r{token=})
    end
  end

  describe "email collisions" do
    it "auto-links Google when the email is verified", :aggregate_failures do
      existing = create(:user, email: "oauth@example.com")
      mock_google(verified: true)

      expect { get "/users/auth/google_oauth2/callback" }.not_to change(User, :count)

      expect(existing.oauth_identities.count).to eq(1)
      expect(response).to redirect_to(%r{token=})
    end

    it "refuses to auto-link Google when the email is unverified", :aggregate_failures do
      existing = create(:user, email: "oauth@example.com")
      mock_google(verified: false)

      get "/users/auth/google_oauth2/callback"

      expect(existing.oauth_identities.count).to eq(0)
      expect(response).to redirect_to("#{frontend}/login?error=email_taken")
    end

    it "never auto-links Patreon", :aggregate_failures do
      existing = create(:user, email: "patron@example.com")
      mock_patreon

      get "/users/auth/patreon/callback"

      expect(existing.oauth_identities.count).to eq(0)
      expect(response).to redirect_to("#{frontend}/login?error=email_taken")
    end
  end

  describe "connecting a provider to an existing account" do
    let!(:user) { create(:user) }

    # The connect_token rides through the real request phase: OmniAuth stores
    # request params in the session and restores them as omniauth.params in
    # the callback phase.
    def start_connect_flow(token)
      get "/users/auth/patreon", params: { connect_token: token }
      follow_redirect!
    end

    it "attaches the identity and redirects to settings", :aggregate_failures do
      mock_patreon

      expect { start_connect_flow(connect_token_for(user)) }.not_to change(User, :count)

      expect(user.oauth_identities.pluck(:provider)).to eq([ "patreon" ])
      expect(response).to redirect_to("#{frontend}/settings?connected=patreon")
    end

    it "rejects an identity already linked to another user", :aggregate_failures do
      create(:user_oauth_identity, :patreon, uid: "patreon-uid-1")
      mock_patreon

      start_connect_flow(connect_token_for(user))

      expect(user.oauth_identities.count).to eq(0)
      expect(response).to redirect_to("#{frontend}/settings?error=identity_taken")
    end

    it "ignores an expired connect token and falls through to signup/login", :aggregate_failures do
      mock_patreon

      expect { start_connect_flow(connect_token_for(user, expires_in: -1.minute)) }.to change(User, :count).by(1)

      expect(user.oauth_identities.count).to eq(0)
      expect(response).to redirect_to(%r{/auth/callback/patreon\?token=})
    end
  end

  describe "missing email" do
    it "redirects with email_required when the provider gives no email" do
      mock_patreon(email: nil)

      get "/users/auth/patreon/callback"

      expect(response).to redirect_to("#{frontend}/login?error=email_required")
    end
  end

  describe "failure" do
    it "redirects to the frontend login with an encoded error" do
      mock_google
      OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

      get "/users/auth/google_oauth2/callback"

      follow_redirect! if response.redirect_url&.include?("/users/auth/failure")
      expect(response.redirect_url).to start_with("#{frontend}/login?error=")
    end
  end
end
