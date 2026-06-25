module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Subscriptions are for signed-in users (live progress sync + collaboration).
    # A browser can't set an Authorization header on the WebSocket handshake, so
    # the JWT rides the cable URL as a `token` query param; we decode it exactly
    # like HTTP requests (see JwtAuthenticatable). Guests never open the cable
    # (they make no subscriptions), so rejecting tokenless connections is safe.
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      reject_unauthorized_connection unless current_user
    end

    private

    def find_verified_user
      token = request.params[:token]
      return if token.blank?

      payload = Warden::JWTAuth::TokenDecoder.new.call(token)
      User.find_by(id: payload["sub"], jti: payload["jti"])
    rescue JWT::DecodeError
      nil
    end
  end
end
