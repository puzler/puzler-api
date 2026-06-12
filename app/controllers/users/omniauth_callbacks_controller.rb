class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_oauth("google")
  end

  def patreon
    handle_oauth("patreon")
  end

  def failure
    redirect_to_frontend("/login?error=#{ERB::Util.url_encode(failure_message || 'authentication_failed')}")
  end

  private

  def handle_oauth(provider)
    auth = request.env["omniauth.auth"]

    if (connecting_user = user_from_connect_token)
      return connect_identity(connecting_user, auth, provider)
    end

    return redirect_to_frontend("/login?error=email_required") if auth.info.email.blank? && !UserOauthIdentity.exists?(provider:, uid: auth.uid)

    user = find_or_create_user(auth, provider)
    return if performed? # an error redirect already happened

    redirect_to_frontend("/auth/callback/#{provider}?token=#{user.generate_jwt}")
  end

  def find_or_create_user(auth, provider)
    identity = UserOauthIdentity.find_by(provider:, uid: auth.uid)

    if identity
      update_identity_tokens(identity, auth)
      identity.user
    elsif (existing = auto_linkable_user(auth, provider))
      existing.oauth_identities.create!(identity_attrs(auth, provider))
      existing
    elsif User.exists?(email: auth.info.email)
      # Same email, but we can't verify ownership (e.g. Patreon) — make the
      # user sign in first and connect from Settings.
      redirect_to_frontend("/login?error=email_taken")
      nil
    else
      create_user_from_oauth(auth, provider)
    end
  end

  # Connecting a provider to an already-signed-in account: the SPA passes a
  # short-lived signed token (from the prepareOauthConnect mutation) through
  # the OAuth flow via omniauth.params.
  def connect_identity(user, auth, provider)
    identity = UserOauthIdentity.find_by(provider:, uid: auth.uid)

    if identity && identity.user_id != user.id
      return redirect_to_frontend("/settings?error=identity_taken")
    end

    identity ||= user.oauth_identities.build(provider:, uid: auth.uid)
    identity.assign_attributes(
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token
    )
    identity.save!
    redirect_to_frontend("/settings?connected=#{provider}")
  end

  def user_from_connect_token
    token = request.env["omniauth.params"]&.dig("connect_token")
    return if token.blank?

    user_id = Rails.application.message_verifier(:oauth_connect).verified(token)
    User.find_by(id: user_id)
  end

  # Auto-linking an OAuth identity to an existing account by email is only
  # safe when the provider verified the address — Google attests this;
  # Patreon does not, so a Patreon email collision never auto-links.
  def auto_linkable_user(auth, provider)
    return nil unless provider == "google" && auth.dig("extra", "id_info", "email_verified")

    User.find_by(email: auth.info.email)
  end

  def update_identity_tokens(identity, auth)
    identity.update(
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token
    )
  end

  def identity_attrs(auth, provider)
    {
      provider: provider,
      uid: auth.uid,
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token
    }
  end

  def create_user_from_oauth(auth, provider)
    user = User.new(
      email: auth.info.email,
      username: generate_username(auth.info.name || auth.info.email.split("@").first),
      password: Devise.friendly_token[0, 20],
      password_set: false,
      avatar_url: auth.info.image
    )
    user.save!
    user.oauth_identities.create!(identity_attrs(auth, provider))
    user
  end

  def generate_username(base)
    candidate = base.downcase.gsub(/[^a-z0-9_]/, "_").first(25)
    candidate = "user" if candidate.blank?
    return candidate unless User.exists?(username: candidate)

    "#{candidate}_#{SecureRandom.hex(3)}"
  end

  def redirect_to_frontend(path)
    redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}#{path}", allow_other_host: true
  end
end
