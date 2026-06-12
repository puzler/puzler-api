class Users::AvatarsController < ApplicationController
  include JwtAuthenticatable

  before_action :require_current_user!

  ALLOWED_TYPES = %w[image/png image/jpeg image/webp].freeze
  MAX_BYTES = 5.megabytes

  # PUT /me/avatar (multipart: avatar=<file>)
  def update
    file = params[:avatar]

    unless file.respond_to?(:content_type)
      return render json: { errors: [ "No file provided" ] }, status: :unprocessable_entity
    end

    unless ALLOWED_TYPES.include?(file.content_type)
      return render json: { errors: [ "Avatar must be a PNG, JPEG, or WebP image" ] }, status: :unprocessable_entity
    end

    if file.size > MAX_BYTES
      return render json: { errors: [ "Avatar must be 5MB or smaller" ] }, status: :unprocessable_entity
    end

    current_user.avatar.attach(file)
    render json: { data: { user: UserSerializer.new(current_user).as_json } }, status: :ok
  end

  # DELETE /me/avatar
  def destroy
    current_user.avatar.purge if current_user.avatar.attached?
    render json: { data: { user: UserSerializer.new(current_user).as_json } }, status: :ok
  end
end
