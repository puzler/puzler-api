# frozen_string_literal: true

Devise.setup do |config|
  require 'devise/orm/active_record'

  config.navigational_formats = []
  config.mailer_sender = 'noreply@puzler.app'
  config.case_insensitive_keys = %i[email display_name]
  config.strip_whitespace_keys = %i[email display_name]
  config.paranoid = true
  config.skip_session_storage = %i[http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.send_email_changed_notification = true
  config.send_password_change_notification = true
  config.confirm_within = 3.days
  config.reconfirmable = true
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_keys = %i[email]
  config.reset_password_within = 6.hours
end
