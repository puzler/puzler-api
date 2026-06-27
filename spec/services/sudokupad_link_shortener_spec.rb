require "rails_helper"

RSpec.describe SudokupadLinkShortener do
  let(:endpoint) { "https://sudokupad.app/admin/createlink" }

  it "posts the payload and returns the short URL on success" do
    stub_request(:post, endpoint)
      .with(body: { "puzzle" => "fpuzzlesABC" })
      .to_return(status: 200, body: { result: "success", shortid: "0jct63gsc3" }.to_json)

    expect(described_class.call("fpuzzlesABC")).to eq("https://sudokupad.app/0jct63gsc3")
  end

  it "raises on a non-success result" do
    stub_request(:post, endpoint).to_return(status: 200, body: { result: "error" }.to_json)
    expect { described_class.call("x") }.to raise_error(described_class::Error)
  end

  it "raises on an HTTP error status" do
    stub_request(:post, endpoint).to_return(status: 500, body: "nope")
    expect { described_class.call("x") }.to raise_error(described_class::Error)
  end

  it "raises on a timeout" do
    stub_request(:post, endpoint).to_timeout
    expect { described_class.call("x") }.to raise_error(described_class::Error)
  end

  it "raises on an empty payload without calling out", :aggregate_failures do
    expect { described_class.call("") }.to raise_error(described_class::Error)
    expect(a_request(:post, endpoint)).not_to have_been_made
  end
end
