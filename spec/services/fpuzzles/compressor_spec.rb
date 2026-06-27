require "rails_helper"

RSpec.describe Fpuzzles::Compressor do
  it "prefixes the payload with fpuzzles" do
    expect(described_class.compress({ "a" => 1 })).to start_with("fpuzzles")
  end

  it "round-trips a hash through compress/decompress" do
    data = { "size" => 9, "grid" => [ [ {} ] ], "title" => "x" }
    expect(described_class.decompress(described_class.compress(data))).to eq(data)
  end

  # Guards that the gem stays byte-compatible with the JS lz-string lib SudokuPad
  # uses — this exact base64 was produced by JS lz-string compressToBase64.
  it "matches JS lz-string compressToBase64 byte-for-byte" do
    data = { "size" => 9, "grid" => Array.new(9) { Array.new(9) { {} } }, "title" => "Spike", "author" => "puzler" }
    js = "N4IgzglgXgpiBcBOANCA5gJwgEwQbT2AF9ljSSzKLryBdZQmq8l54+x1p7rjtn/nQaCR3PgIm9hk0UM6zR4rssX0QAFwjqANnHggAygAcIAazioAhgFd1ACwD2GBCCPWou50SA=="
    expect(described_class.compress(data)).to eq("fpuzzles#{js}")
  end
end
