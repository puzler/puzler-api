require "rails_helper"

RSpec.describe "Mutation: uploadAvatar", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($file: Upload!) {
        uploadAvatar(input: { file: $file }) {
          user { id avatarUrl }
          errors
        }
      }
    GQL
  end

  let(:user) { create(:user) }

  # In unit tests we hand the Upload scalar a real uploaded file directly,
  # bypassing the multipart middleware (exercised by the request-level curl).
  def wrapped_file(filename: "avatar.png", content_type: "image/png")
    ApolloUploadServer::Wrappers::UploadedFile.new(
      ActionDispatch::Http::UploadedFile.new(
        tempfile: Rails.root.join("spec/fixtures/files/avatar.png").open,
        filename: filename,
        type: content_type
      )
    )
  end

  def upload(context: auth_context(user), **file_opts)
    execute_query(mutation, variables: { "file" => wrapped_file(**file_opts) }, context: context)
  end

  def stored_longest_side
    image = Vips::Image.new_from_buffer(user.avatar.download, "")
    [ image.width, image.height ].max
  end

  it "attaches a normalized WebP avatar", :aggregate_failures do
    expect(gql_data(upload, "uploadAvatar", "errors")).to be_empty
    expect(user.reload.avatar.blob.content_type).to eq("image/webp")
    expect(stored_longest_side).to be <= 512
  end

  it "rejects a disallowed content type", :aggregate_failures do
    result = upload(content_type: "text/plain")

    expect(gql_data(result, "uploadAvatar", "errors")).to eq([ "Avatar must be a PNG, JPEG, or WebP image" ])
    expect(user.reload.avatar).not_to be_attached
  end

  it "requires authentication" do
    result = upload(context: {})
    expect(gql_errors(result).first["message"]).to eq("Authentication required")
  end
end
