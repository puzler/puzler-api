class Users::PasswordsController < Devise::PasswordsController
  respond_to :json

  # POST /users/password — send reset instructions.
  # Paranoid mode: identical response whether or not the email exists.
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    render json: { message: "If that email exists, reset instructions have been sent." }, status: :ok
  end

  # PUT /users/password — reset with token from the email link.
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    if resource.errors.empty?
      render json: {
        data: {
          user: UserSerializer.new(resource).as_json
        }
      }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
