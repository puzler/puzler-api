require "rails_helper"

RSpec.describe "Share pages", type: :request do
  let(:collection) do
    create(:collection, visibility: :public, title: "Foggy Hunt <3", description: "A misty adventure.")
  end

  def share_body(id, params = {})
    get("/share/collections/#{id}", params:)
    response.body
  end

  it "serves Open Graph tags and bounces humans to the app", :aggregate_failures do
    body = share_body(collection.id)
    expect(body).to include(%(property="og:title" content="Foggy Hunt &lt;3"))
    expect(body).to include(%(property="og:description" content="A misty adventure."))
    expect(body).to include("refresh").and include("/collections/#{collection.id}")
  end

  it "includes the og cover image when one is attached", :aggregate_failures do
    collection.cover_image.attach(
      io: Rails.root.join("spec/fixtures/files/avatar.png").open,
      filename: "cover.png", content_type: "image/png"
    )
    expect(share_body(collection.id)).to include(%(property="og:image"))
  end

  it "hides private collections" do
    secret = create(:collection, visibility: :private)
    share_body(secret.id)
    expect(response).to have_http_status(:not_found)
  end

  it "admits unlisted collections only with their token and carries it forward", :aggregate_failures do
    hidden = create(:collection, visibility: :unlisted)
    share_body(hidden.id)
    expect(response).to have_http_status(:not_found)
    expect(share_body(hidden.id, t: hidden.share_token)).to include("?t=#{hidden.share_token}")
  end
end
