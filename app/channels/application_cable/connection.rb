module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Accept signed-in users (JWT in ?token=) and guests (an opaque, client-
    # generated ?guest= token from localStorage). A guest token is self-asserted
    # and grants nothing on its own — every stream/mutation re-checks
    # accessible_by?(actor), so it reaches a play only once that guest owns or
    # joins it. Reject only when BOTH are absent (a truly anonymous socket).
    identified_by :current_user, :guest_token

    def connect
      self.current_user = find_verified_user
      self.guest_token = request.params[:guest].presence
      reject_unauthorized_connection unless current_user || guest_token
    end

    def current_actor
      Actor.from_context(current_user: current_user, guest_token: guest_token)
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
