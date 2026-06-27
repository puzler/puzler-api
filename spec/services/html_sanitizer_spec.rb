require "rails_helper"

RSpec.describe HtmlSanitizer do
  def clean(html, hosts: [ "cdn.example.com" ])
    described_class.sanitize(html, allowed_image_hosts: hosts)
  end

  it "strips script tags and their contents" do
    result = clean("<p>hi</p><script>alert(1)</script>")
    expect(result).to eq("<p>hi</p>")
  end

  it "strips event-handler attributes" do
    expect(clean(%(<p onclick="evil()">hi</p>))).to eq("<p>hi</p>")
  end

  it "strips inline styles" do
    expect(clean(%(<p style="color:red">hi</p>))).to eq("<p>hi</p>")
  end

  it "drops a javascript: href but keeps the link text", :aggregate_failures do
    result = clean(%(<a href="javascript:alert(1)">x</a>))
    expect(result).to include(">x</a>")
    expect(result).not_to include("javascript")
    expect(result).not_to include("href")
  end

  it "marks safe links nofollow / noopener / new-tab", :aggregate_failures do
    result = clean(%(<a href="https://example.com/p">x</a>))
    expect(result).to include('href="https://example.com/p"')
    expect(result).to include('rel="nofollow noopener noreferrer"')
    expect(result).to include('target="_blank"')
  end

  it "keeps images served from an allowed host" do
    result = clean(%(<img src="https://cdn.example.com/a.webp" alt="diagram">))
    expect(result).to include('src="https://cdn.example.com/a.webp"')
  end

  it "drops images from a foreign host" do
    expect(clean(%(<img src="https://evil.example/a.png">))).not_to include("<img")
  end

  it "drops data: URI images" do
    expect(clean(%(<img src="data:image/png;base64,AAAA">))).not_to include("<img")
  end

  it "keeps the allowed formatting tags" do
    html = "<h1>T</h1><strong>b</strong><em>i</em><ul><li>x</li></ul><blockquote>q</blockquote>"
    expect(clean(html)).to eq(html)
  end

  it "strips disallowed tags like iframe and style", :aggregate_failures do
    result = clean("<iframe src='x'></iframe><style>p{}</style><p>ok</p>")
    expect(result).not_to include("iframe")
    expect(result).not_to include("<style")
    expect(result).to include("<p>ok</p>")
  end

  it "raises for oversized input" do
    expect { clean("<p>#{'a' * 100_001}</p>") }.to raise_error(HtmlSanitizer::TooLarge)
  end
end
