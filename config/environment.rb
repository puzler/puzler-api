# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

sendgrid_api_key = Rails.application.credentials.dig(:sendgrid, :api_key) || ENV.fetch('SENDGRID_API_KEY', nil)
if sendgrid_api_key.present?
  ActionMailer::Base.smtp_settings = {
    user_name: 'apikey',
    password: sendgrid_api_key,
    domain: 'puzler.app',
    address: 'smtp.sendgrid.net',
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }
end
