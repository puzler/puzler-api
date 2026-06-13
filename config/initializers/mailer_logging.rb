# Surface mail delivery outcomes at info level. Rails logs "Delivered mail …"
# only at debug, which is invisible in production (info) — so a failed or
# successful send leaves no trace in the logs. This logs both, keyed by the
# SMTP message_id (which also appears in the Resend dashboard) for correlation.
# Recipients are masked to keep raw email addresses out of the logs.
module MailerLogging
  # "charliepugh92@gmail.com" -> "c***@gmail.com"
  def self.mask(address)
    local, _, domain = address.to_s.partition("@")
    return "***" if local.empty?

    "#{local[0]}***@#{domain}"
  end
end

ActiveSupport::Notifications.subscribe("deliver.action_mailer") do |event|
  payload = event.payload
  recipients = Array(payload[:to]).map { |addr| MailerLogging.mask(addr) }.join(", ")

  if (exception = payload[:exception_object])
    Rails.logger.error(
      "[mail] FAILED to=#{recipients} subject=#{payload[:subject].inspect} " \
      "error=#{exception.class}: #{exception.message}"
    )
  elsif payload[:perform_deliveries]
    Rails.logger.info(
      "[mail] delivered to=#{recipients} subject=#{payload[:subject].inspect} " \
      "message_id=#{payload[:message_id]} (#{event.duration.round(1)}ms)"
    )
  end
end
