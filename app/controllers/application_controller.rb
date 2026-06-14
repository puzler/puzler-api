class ApplicationController < ActionController::API
  def root
    render json: { message: "Hello There", **AppVersion.info }, status: :ok
  end
end
