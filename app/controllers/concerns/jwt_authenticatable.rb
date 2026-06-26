# Bearer-token authentication for non-Devise endpoints (GraphQL, avatar upload).
# Decodes through warden-jwt_auth so the secret/algorithm/expiry always match
# what devise-jwt encoded, and honors jti revocation.
module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user_from_token!
  end

  private

  def authenticate_user_from_token!
    header = request.headers["Authorization"]
    return unless header&.start_with?("Bearer ")

    token = header.split(" ").last
    payload = Warden::JWTAuth::TokenDecoder.new.call(token)
    @current_user = User.find_by(id: payload["sub"], jti: payload["jti"])
  rescue JWT::DecodeError
    nil
  end

  def current_user
    @current_user
  end

  # Guests identify with an opaque, client-generated token (localStorage), sent
  # as a header since they have no JWT. Self-asserted — access is still gated by
  # PuzzlePlay#accessible_by?.
  def guest_token
    request.headers["X-Guest-Token"].presence
  end

  def require_current_user!
    head :unauthorized unless current_user
  end
end
