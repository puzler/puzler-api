require "rails_helper"

RSpec.describe "Collection page mutations", type: :graphql do
  let(:user) { create(:user) }
  let(:collection) { create(:collection, author: user) }

  def wrapped_file(content_type: "image/png")
    ApolloUploadServer::Wrappers::UploadedFile.new(
      ActionDispatch::Http::UploadedFile.new(
        tempfile: Rails.root.join("spec/fixtures/files/avatar.png").open,
        filename: "cover.png", type: content_type
      )
    )
  end

  describe "updateCollectionPageDescription" do
    let(:mutation) do
      <<~GQL
        mutation($collectionId: ID!, $html: String!) {
          updateCollectionPageDescription(input: { collectionId: $collectionId, html: $html }) {
            collection { id pageDescriptionHtml }
            errors
          }
        }
      GQL
    end

    def run(html, context: auth_context(user))
      execute_query(mutation, variables: { collectionId: collection.id, html: html }, context: context)
    end

    it "stores sanitized HTML, stripping scripts, handlers, and foreign images", :aggregate_failures do
      html = '<p>Hi</p><script>evil()</script><p onclick="x()">y</p><img src="https://evil.example/x.png">'
      stored = gql_data(run(html), "updateCollectionPageDescription", "collection")["pageDescriptionHtml"]
      expect(stored).to include("<p>Hi</p>")
      [ "script", "onclick", "evil.example" ].each { |bad| expect(stored).not_to include(bad) }
    end

    it "requires the author" do
      result = run("<p>hi</p>", context: auth_context(create(:user)))
      expect(gql_errors(result).first["message"]).to eq("Collection not found")
    end

    it "requires authentication" do
      expect(gql_errors(run("<p>hi</p>", context: {})).first["message"]).to eq("Authentication required")
    end
  end

  describe "uploadCollectionDescriptionImage" do
    let(:mutation) do
      <<~GQL
        mutation($collectionId: ID!, $file: Upload!) {
          uploadCollectionDescriptionImage(input: { collectionId: $collectionId, file: $file }) { url errors }
        }
      GQL
    end

    def upload(context: auth_context(user), **file_opts)
      execute_query(mutation, variables: { collectionId: collection.id, file: wrapped_file(**file_opts) },
        context: context)
    end

    it "stores a normalized WebP image and returns its URL", :aggregate_failures do
      data = gql_data(upload, "uploadCollectionDescriptionImage")
      expect(data["errors"]).to be_empty
      expect(data["url"]).to be_present
      expect(collection.reload.description_images).to be_attached
      expect(collection.description_images.first.blob.content_type).to eq("image/webp")
    end

    it "rejects a disallowed content type", :aggregate_failures do
      data = gql_data(upload(content_type: "text/plain"), "uploadCollectionDescriptionImage")
      expect(data["errors"]).to eq([ "Image must be a PNG, JPEG, or WebP image" ])
      expect(collection.reload.description_images).not_to be_attached
    end

    it "requires the author" do
      result = upload(context: auth_context(create(:user)))
      expect(gql_errors(result).first["message"]).to eq("Collection not found")
    end
  end

  describe "uploadCollectionCoverImage / removeCollectionCoverImage" do
    let(:upload_mutation) do
      <<~GQL
        mutation($collectionId: ID!, $file: Upload!) {
          uploadCollectionCoverImage(input: { collectionId: $collectionId, file: $file }) {
            collection { id coverImageUrl coverThumbUrl }
            errors
          }
        }
      GQL
    end
    let(:remove_mutation) do
      <<~GQL
        mutation($collectionId: ID!) {
          removeCollectionCoverImage(input: { collectionId: $collectionId }) {
            collection { id coverImageUrl }
            errors
          }
        }
      GQL
    end

    def upload_cover(context: auth_context(user))
      result = execute_query(upload_mutation, variables: { collectionId: collection.id, file: wrapped_file },
        context: context)
      gql_data(result, "uploadCollectionCoverImage", "collection")
    end

    def remove_cover
      result = execute_query(remove_mutation, variables: { collectionId: collection.id },
        context: auth_context(user))
      gql_data(result, "removeCollectionCoverImage", "collection")
    end

    it "attaches a normalized cover and serves both crop URLs", :aggregate_failures do
      data = upload_cover
      expect(data.values_at("coverImageUrl", "coverThumbUrl")).to all(be_present)
      expect(collection.reload.cover_image).to be_attached
      expect(collection.cover_image.blob.content_type).to eq("image/webp")
    end

    it "removes the cover", :aggregate_failures do
      upload_cover
      data = remove_cover
      expect(data["coverImageUrl"]).to be_nil
      expect(collection.reload.cover_image).not_to be_attached
    end

    it "requires the author" do
      result = execute_query(upload_mutation, variables: { collectionId: collection.id, file: wrapped_file },
        context: auth_context(create(:user)))
      expect(gql_errors(result).first["message"]).to eq("Collection not found")
    end
  end


  describe "updateCollection kind" do
    let(:kind_mutation) do
      <<~GQL
        mutation($id: ID!, $attrs: CollectionAttrsInput!) {
          updateCollection(input: { id: $id, attrs: $attrs }) { collection { id kind } errors }
        }
      GQL
    end

    def set_kind(kind)
      result = execute_query(kind_mutation, variables: { id: collection.id, attrs: { kind: } },
        context: auth_context(user))
      gql_data(result, "updateCollection", "collection")
    end

    it "switches kind", :aggregate_failures do
      expect(set_kind("HUNT")["kind"]).to eq("HUNT")
      expect(collection.reload.kind_hunt?).to be(true)
    end
  end

  describe "updateCollection accent attrs" do
    let(:mutation) do
      <<~GQL
        mutation($id: ID!, $attrs: CollectionAttrsInput!) {
          updateCollection(input: { id: $id, attrs: $attrs }) {
            collection { id accentColor bgTreatment titleFont }
            errors
          }
        }
      GQL
    end

    def update_accents(attrs)
      result = execute_query(mutation, variables: { id: collection.id, attrs: },
        context: auth_context(user))
      gql_data(result, "updateCollection", "collection")
    end

    it "persists the curated page accents", :aggregate_failures do
      data = update_accents(accentColor: "FOREST", bgTreatment: "PARCHMENT", titleFont: "SERIF")
      expect(data).to include("accentColor" => "FOREST", "bgTreatment" => "PARCHMENT", "titleFont" => "SERIF")
      expect(collection.reload).to have_attributes(accent_color: "forest", bg_treatment: "parchment",
        title_font: "serif")
    end
  end
end
