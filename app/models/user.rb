# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_token :jwt_salt

  has_many :user_o_auth_providers, dependent: :destroy

  devise :database_authenticatable, :registerable, :confirmable,
         :trackable, :recoverable, :validatable

  before_validation :strip_whitespace
  before_create :set_default_values
  validates :display_name, uniqueness: { case_sensitive: false }

  def self.from_jwt(token)
    data = decode_jwt(token)
    return if data.nil?

    user = User.find_by(id: data[:sub])
    return if user.nil?
    return if user.jwt_salt != data[:salt]
    return if JwtDenylist.exists?(jti: data[:jti])

    user
  end

  def self.decode_jwt(token)
    JWT.decode(
      token,
      Rails.application.credentials.dig(:devise, :jwt_secret),
      true,
      algorithm: 'HS256'
    )[0].with_indifferent_access
  rescue StandardError
    nil
  end

  # user_data: { id: string, email: string, name: string }
  def self.from_oauth(user_data, provider)
    oauth_user = UserOAuthProvider.find_by(
      oauth_id: user_data[:id],
      provider: provider.provider_name
    )
    return valid_oauth_user?(oauth_user) if oauth_user.present?

    user = User.find_by('LOWER(email) = ?', user_data[:email].downcase)
    return create_oauth_user(user_data, provider) if user.nil?

    oauth_user = user.add_oauth_provider(user_data, provider)
    valid_oauth_user? oauth_user
  end

  def generate_jwt
    JWT.encode(
      jwt_payload,
      Rails.application.credentials.dig(:devise, :jwt_secret),
      'HS256'
    )
  end

  def add_oauth_provider(user_data, provider)
    user_o_auth_providers.create(
      oauth_id: user_data[:id],
      provider: provider.provider_name,
      confirmed_at: provider.require_email_confirmation? ? nil : DateTime.now
    )
  end

  private

  def self.create_oauth_user(user_data, provider)
    user = User.create(
      email: user_data[:email],
      first_name: user_data[:first_name],
      last_name: user_data[:last_name],
      password: Devise.friendly_token,
      confirmed_at: provider.require_email_confirmation? ? nil : DateTime.now
    )
    return user if user.errors.any?

    valid_oauth_user?(
      user.user_o_auth_providers.create(
        provider: provider.provider_name,
        oauth_id: user_data[:id],
        confirmed_at: DateTime.now
      )
    )
  end
  private_class_method :create_oauth_user

  def self.valid_oauth_user?(oauth_user)
    user = oauth_user.user

    user.errors.add(:base, 'OAuth provider has not been confirmed') unless oauth_user.confirmed?
    oauth_user.errors.full_messages.each do |message|
      user.errors.add(:base, message)
    end

    user
  end
  private_class_method :valid_oauth_user?

  def strip_whitespace
    columns = User.columns.select { |c| c.sql_type_metadata.type == :string }
    columns.map(&:name).each do |column|
      send(column).try(&:strip!)
    end
  end

  def jwt_payload
    {
      sub: id,
      salt: jwt_salt,
      jti: SecureRandom.uuid,
      iat: Time.now.to_i,
      exp: 30.days.from_now.to_i
    }
  end

  def set_default_values
    self.display_name ||= email.split('@').first
    return if validate_attribute(:display_name)

    number_to_append = 1
    number_to_append += 1 while validate_attribute(:display_name, "#{display_name}#{number_to_append}")
    self.display_name = "#{display_name}#{number_to_append}"
  end
end
