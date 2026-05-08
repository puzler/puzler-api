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

  def respond_to_on_destroy
    if request.headers["Authorization"].present?
      jwt_payload = JWT.decode(
        request.headers["Authorization"].split.last,
        Rails.application.credentials.secret_key_base
      ).first
      current_user = User.find(jwt_payload["sub"])
    end

    if current_user
      render json: { message: "Signed out successfully." }, status: :ok
    else
      render json: { message: "Could not sign out." }, status: :unauthorized
    end
  end
end
