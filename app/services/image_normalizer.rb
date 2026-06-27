require "image_processing/vips"

# Validates and normalizes an uploaded image: downscales to <= max_dimension
# (longest side, aspect preserved), bakes in EXIF orientation (autorot on by
# default), strips metadata, and re-encodes to WebP — so stored images stay
# small no matter what was uploaded. The byte cap is a pre-processing DoS guard.
#
# Generalized from the avatar pipeline so different surfaces (avatars, puzzle
# description images, ...) can pick their own size limits and error wording.
class ImageNormalizer
  class InvalidImage < StandardError; end

  ALLOWED_TYPES = %w[image/png image/jpeg image/webp].freeze

  def initialize(upload, max_bytes:, max_dimension:, label: "Image")
    @upload = upload
    @max_bytes = max_bytes
    @max_dimension = max_dimension
    @label = label
  end

  # Returns a processed IO ready to attach, or raises InvalidImage with a
  # user-facing message.
  def call
    validate!

    ImageProcessing::Vips
      .source(@upload.tempfile)
      .resize_to_limit(@max_dimension, @max_dimension)
      .convert("webp")
      .saver(quality: 80, strip: true)
      .call
  rescue Vips::Error, ImageProcessing::Error
    raise InvalidImage, "That image could not be processed"
  end

  private

  def validate!
    unless ALLOWED_TYPES.include?(@upload.content_type)
      raise InvalidImage, "#{@label} must be a PNG, JPEG, or WebP image"
    end

    raise InvalidImage, "#{@label} must be #{@max_bytes / 1.megabyte}MB or smaller" if @upload.size > @max_bytes
  end
end
