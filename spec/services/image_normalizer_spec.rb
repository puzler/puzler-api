require "rails_helper"

RSpec.describe ImageNormalizer do
  def uploaded(filename: "avatar.png", type: "image/png")
    ActionDispatch::Http::UploadedFile.new(
      tempfile: Rails.root.join("spec/fixtures/files/avatar.png").open,
      filename: filename,
      type: type
    )
  end

  it "downscales to the longest side and re-encodes as WebP", :aggregate_failures do
    io = described_class.new(uploaded, max_bytes: 5.megabytes, max_dimension: 32).call
    image = Vips::Image.new_from_buffer(io.read, "")
    expect([ image.width, image.height ].max).to be <= 32
  end

  it "rejects a disallowed content type with the configured label" do
    expect {
      described_class.new(uploaded(type: "text/plain"), max_bytes: 5.megabytes, max_dimension: 512,
        label: "Description image").call
    }.to raise_error(ImageNormalizer::InvalidImage, "Description image must be a PNG, JPEG, or WebP image")
  end

  it "rejects files over the byte cap" do
    file = uploaded
    allow(file).to receive(:size).and_return(10.megabytes)

    expect {
      described_class.new(file, max_bytes: 8.megabytes, max_dimension: 1600, label: "Description image").call
    }.to raise_error(ImageNormalizer::InvalidImage, "Description image must be 8MB or smaller")
  end
end
