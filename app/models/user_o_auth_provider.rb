# frozen_string_literal: true

class UserOAuthProvider < ApplicationRecord
  belongs_to :user
  has_secure_token :confirmation_token

  enum provider: { google: 0, facebook: 1, patreon: 2 }

  validates :provider, uniqueness: { scope: :user_id }
  validates :oauth_id, uniqueness: { scope: :provider }

  before_create :check_pre_confirmed
  after_create :send_confirmation_email, unless: :confirmed?

  def confirmed?
    confirmed_at.present?
  end

  def resend_confirmation_email
    return if confirmed?

    send_confirmation_email
  end

  def self.confirm_by_token(token)
    record = find_by(confirmation_token: token)
    return record unless record&.valid_for_confirmation?

    record.confirm!
    record
  end

  def valid_for_confirmation?
    record.errors.add(:base, 'Link is already confirmed') if record.confirmed?
    record.errors.add(:base, 'Confirmation link has expired') if record.confirmation_sent_at < 3.days.ago

    record.errors.empty?
  end

  def confirm!
    update(
      confirmed_at: DateTime.now,
      confirmation_token: nil,
      confirmation_sent_at: nil
    )
  end

  private

  def check_pre_confirmed
    return unless confirmed?

    self.confirmation_token = nil
  end

  def confirmation_token!
    return if confirmed?

    regenerate_confirmation_token if confirmation_token.nil?
    confirmation_token
  end

  def send_confirmation_email
    return if confirmed?

    Devise::AuthProviderMailer.confirm_provider(user, confirmation_token!, provider:).deliver
    update(confirmation_sent_at: DateTime.now)
  end
end
