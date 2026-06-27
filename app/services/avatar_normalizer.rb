# Validates and normalizes an uploaded avatar: downscales to <=512px (longest
# side, aspect preserved), strips metadata, re-encodes to WebP. Thin wrapper
# over the generic ImageNormalizer so the avatar limits live in one place.
class AvatarNormalizer
  # Keep AvatarNormalizer::InvalidImage working for existing callers.
  InvalidImage = ImageNormalizer::InvalidImage

  MAX_BYTES = 5.megabytes
  MAX_DIMENSION = 512

  def initialize(upload)
    @upload = upload
  end

  def call
    ImageNormalizer.new(@upload, max_bytes: MAX_BYTES, max_dimension: MAX_DIMENSION, label: "Avatar").call
  end
end
