# Shared behavior for models including RichDescription: embedded description
# images are purged once their blob URL no longer appears in the rich HTML.
# The including context provides `record`.
RSpec.shared_examples "a model with a rich description" do
  def attach_image(record)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join("spec/fixtures/files/avatar.png").open,
      filename: "img.png", content_type: "image/png"
    )
    record.description_images.attach(blob)
    blob
  end

  it "purges images missing from the HTML and keeps referenced ones", :aggregate_failures do
    kept, orphan = attach_image(record), attach_image(record)
    record.update!(record.class.rich_description_attribute => "<p><img src=\"/blobs/#{kept.signed_id}\"></p>")

    expect { record.reconcile_description_images! }.to have_enqueued_job(ActiveStorage::PurgeJob).once
    expect(record.reload.description_images.blobs).to include(kept)
    expect(record.reload.description_images.blobs).not_to include(orphan)
  end
end
