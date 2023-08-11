
api_key = Rails.application.credentials.bugsnag_api_key || ENV.fetch('BUGSNAG_API_KEY', nil)
if api_key.present?
  Bugsnag.configure do |config|
    config.api_key = api_key
  end
end
