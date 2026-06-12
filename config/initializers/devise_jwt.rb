Devise::JWT.configure do |config|
  # Single source of truth for the JWT secret. All decode sites must read
  # Warden::JWTAuth.config.secret rather than referencing a secret directly.
  config.secret = Rails.application.credentials.devise_jwt_secret || Rails.application.credentials.secret_key_base
  config.expiration_time = 7.days.to_i
  config.dispatch_requests = [
    [ "POST", %r{^/users/sign_in$} ],
    [ "POST", %r{^/users$} ] # signup returns a JWT too — no second login needed
  ]
  config.revocation_requests = [
    [ "DELETE", %r{^/users/sign_out$} ]
  ]
end
