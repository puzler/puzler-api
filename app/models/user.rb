# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :trackable, :recoverable, :validatable

  before_create :set_jwt_salt

  def self.from_jwt(token)
    data = decode_jwt(token)
    return if data.nil?

    user = User.find_by(id: data[:sub])
    return if user.nil?
    return if user.jwt_salt != data[:salt]
    return if JwtDenylist.where(jti: data[:jti]).exists?

    user
  end

  def self.from_oauth(user_data, provider)
    user = find_by(uid: user_data[:id], provider: provider)
    return user if user.present?

    name_parts = user_data[:name].split
    password = Devise.friendly_token
    create(
      email: user_data[:email],
      password: password,
      display_name: user_data[:email].split('@').first,
      first_name: name_parts[0],
      last_name: name_parts[1],
      provider: provider,
      uid: user_data[:id],
      confirmed_at: DateTime.now,
      confirmation_token: nil
    )
  end

  def generate_jwt
    JWT.encode(
      jwt_payload,
      Rails.application.credentials.dig(:devise, :jwt_secret),
      'HS256'
    )
  end

  def cycle_jwt_salt
    update(jwt_salt: Devise.friendly_token)
  end

  private

  def jwt_payload
    {
      sub: id,
      salt: jwt_salt,
      jti: SecureRandom.uuid,
      iat: Time.now.to_i,
      exp: 30.days.from_now.to_i
    }
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
  private_class_method :decode_jwt

  def set_jwt_salt
    self.jwt_salt = Devise.friendly_token
  end
end
