class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_oauth("google")
  end

  def patreon
    handle_oauth("patreon")
  end

  def failure
    redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/auth/callback?error=#{failure_message}"
  end

  private

  def handle_oauth(provider)
    auth = request.env["omniauth.auth"]
    identity = UserOauthIdentity.find_by(provider: provider, uid: auth.uid)

    user = if identity
      identity.update(
        access_token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token
      )
      identity.user
    elsif current_user
      current_user.oauth_identities.create!(
        provider: provider,
        uid: auth.uid,
        access_token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token
      )
      current_user
    else
      create_user_from_oauth(auth, provider)
    end

    sign_in user
    token = user.generate_jwt
    redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/auth/callback?token=#{token}"
  end

  def create_user_from_oauth(auth, provider)
    user = User.new(
      email: auth.info.email,
      username: generate_username(auth.info.name || auth.info.email.split("@").first),
      password: Devise.friendly_token[0, 20]
    )
    user.save!
    user.oauth_identities.create!(
      provider: provider,
      uid: auth.uid,
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token
    )
    user
  end

  def generate_username(base)
    candidate = base.downcase.gsub(/[^a-z0-9_]/, "_").first(25)
    candidate = "user" if candidate.blank?
    return candidate unless User.exists?(username: candidate)

    "#{candidate}_#{SecureRandom.hex(3)}"
  end
end
