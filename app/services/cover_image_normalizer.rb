# Validates and normalizes an uploaded collection cover: downscales to
# <=2000px (longest side, aspect preserved), strips metadata, re-encodes to
# WebP. Thin wrapper over the generic ImageNormalizer so the cover limits live
# in one place; the hero/card crops are ActiveStorage variants on the model.
class CoverImageNormalizer
  InvalidImage = ImageNormalizer::InvalidImage

  MAX_BYTES = 8.megabytes
  MAX_DIMENSION = 2000

  def initialize(upload)
    @upload = upload
  end

  def call
    ImageNormalizer.new(@upload, max_bytes: MAX_BYTES, max_dimension: MAX_DIMENSION, label: "Cover image").call
  end
end
