require "image_processing/vips"

# Validates and normalizes an uploaded avatar: downscales to <=512px (longest
# side, aspect preserved), bakes in EXIF orientation (autorot on by default),
# strips metadata, and re-encodes to WebP — so stored avatars stay tiny no
# matter what was uploaded. The 5MB cap is a pre-processing DoS guard.
class AvatarNormalizer
  class InvalidImage < StandardError; end

  ALLOWED_TYPES = %w[image/png image/jpeg image/webp].freeze
  MAX_BYTES = 5.megabytes
  MAX_DIMENSION = 512

  def initialize(upload)
    @upload = upload
  end

  # Returns a processed IO ready to attach, or raises InvalidImage with a
  # user-facing message.
  def call
    validate!

    ImageProcessing::Vips
      .source(@upload.tempfile)
      .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
      .convert("webp")
      .saver(quality: 80, strip: true)
      .call
  rescue Vips::Error, ImageProcessing::Error
    raise InvalidImage, "That image could not be processed"
  end

  private

  def validate!
    unless ALLOWED_TYPES.include?(@upload.content_type)
      raise InvalidImage, "Avatar must be a PNG, JPEG, or WebP image"
    end

    raise InvalidImage, "Avatar must be 5MB or smaller" if @upload.size > MAX_BYTES
  end
end
