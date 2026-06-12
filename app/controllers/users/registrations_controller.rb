class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  before_action :configure_sign_up_params, only: :create

  private

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username ])
  end

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        data: {
          user: UserSerializer.new(resource).as_json
        }
      }, status: :created
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
