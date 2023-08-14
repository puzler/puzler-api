# frozen_string_literal: true

class CsrfToken < ApplicationRecord
  has_secure_token

  scope :expired?, -> { where('exp < ?', DateTime.now) }

  enum token_type: { oauth: 0 }

  before_create :set_default_expiration

  def self.validate_and_consume(client_token_id:, token:, token_type:)
    record = find_by(client_token_id:, token:, token_type:)
    return false if record.nil?
    return false if record.expired?

    record.destroy!
    true
  end

  def expired?
    exp < DateTime.now
  end

  private

  def set_default_expiration
    self.exp ||= 1.hour.from_now
  end
end
