Devise::JWT.configure do |config|
  config.secret = ENV.fetch("DEVISE_JWT_SECRET_KEY", Rails.application.credentials.secret_key_base)
  config.expiration_time = 7.days.to_i
  config.dispatch_requests = [
    [ "POST", %r{^/users/sign_in$} ]
  ]
  config.revocation_requests = [
    [ "DELETE", %r{^/users/sign_out$} ]
  ]
end
