class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    render json: {
      data: {
        user: UserSerializer.new(resource).as_json
      }
    }, status: :ok
  end

  def respond_to_on_destroy(non_navigational_status: :no_content)
    if request.headers["Authorization"].present?
      jwt_payload = Warden::JWTAuth::TokenDecoder.new.call(
        request.headers["Authorization"].split.last
      )
      current_user = User.find_by(id: jwt_payload["sub"])
    end

    if current_user
      render json: { message: "Signed out successfully." }, status: :ok
    else
      render json: { message: "Could not sign out." }, status: :unauthorized
    end
  rescue JWT::DecodeError
    render json: { message: "Could not sign out." }, status: :unauthorized
  end
end
