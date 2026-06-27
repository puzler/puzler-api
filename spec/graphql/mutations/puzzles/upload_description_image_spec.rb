require "rails_helper"

RSpec.describe "Mutation: uploadDescriptionImage", type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation($puzzleId: ID!, $file: Upload!) {
        uploadDescriptionImage(input: { puzzleId: $puzzleId, file: $file }) { url errors }
      }
    GQL
  end
  let(:user) { create(:user) }
  let(:puzzle) { create(:puzzle, author: user) }

  def wrapped_file(content_type: "image/png")
    ApolloUploadServer::Wrappers::UploadedFile.new(
      ActionDispatch::Http::UploadedFile.new(
        tempfile: Rails.root.join("spec/fixtures/files/avatar.png").open,
        filename: "shot.png", type: content_type
      )
    )
  end

  def upload(context: auth_context(user), id: puzzle.id, **file_opts)
    execute_query(mutation, variables: { puzzleId: id, file: wrapped_file(**file_opts) }, context: context)
  end

  it "stores a normalized WebP image and returns its URL", :aggregate_failures do
    data = gql_data(upload, "uploadDescriptionImage")
    expect(data["errors"]).to be_empty
    expect(data["url"]).to be_present
    expect(puzzle.reload.description_images).to be_attached
    expect(puzzle.description_images.first.blob.content_type).to eq("image/webp")
  end

  it "rejects a disallowed content type", :aggregate_failures do
    data = gql_data(upload(content_type: "text/plain"), "uploadDescriptionImage")
    expect(data["errors"]).to eq([ "Image must be a PNG, JPEG, or WebP image" ])
    expect(puzzle.reload.description_images).not_to be_attached
  end

  it "requires the author" do
    result = upload(context: auth_context(create(:user)))
    expect(gql_errors(result).first["message"]).to eq("Puzzle not found")
  end
end
