require "image_processing/vips"

class Users::AvatarsController < ApplicationController
  include JwtAuthenticatable

  before_action :require_current_user!

  ALLOWED_TYPES = %w[image/png image/jpeg image/webp].freeze
  MAX_BYTES = 5.megabytes
  # Stored avatars are bounded to this on the longest side: enough for a crisp
  # 256px display at 2x, tiny in storage. The client downscales too, but the
  # server is authoritative — uploads are always re-encoded here.
  MAX_DIMENSION = 512

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

    current_user.avatar.attach(io: normalize(file), filename: "avatar.webp", content_type: "image/webp")
    render json: { data: { user: UserSerializer.new(current_user).as_json } }, status: :ok
  rescue Vips::Error, ImageProcessing::Error
    render json: { errors: [ "That image could not be processed" ] }, status: :unprocessable_entity
  end

  # DELETE /me/avatar
  def destroy
    current_user.avatar.purge if current_user.avatar.attached?
    render json: { data: { user: UserSerializer.new(current_user).as_json } }, status: :ok
  end

  private

  # Downscale to MAX_DIMENSION (longest side, aspect preserved), bake in EXIF
  # orientation (autorot is on by default), strip remaining metadata, and
  # re-encode to WebP — so storage stays tiny regardless of what was uploaded.
  def normalize(file)
    ImageProcessing::Vips
      .source(file.tempfile)
      .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
      .convert("webp")
      .saver(quality: 80, strip: true)
      .call
  end
end
