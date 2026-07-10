# A sanitized rich-HTML body with embedded uploaded images (Puzzle pages,
# Collection pages, StoryPage bodies). The including model declares which
# column holds the HTML via `rich_description_on`.
module RichDescription
  extend ActiveSupport::Concern

  included do
    # Images embedded in the rich HTML. Owned here so they can be purged when
    # removed from the HTML (see reconcile_description_images!) or when the
    # record is destroyed.
    has_many_attached :description_images
  end

  class_methods do
    def rich_description_on(attribute)
      @rich_description_attribute = attribute
    end

    def rich_description_attribute
      @rich_description_attribute || :page_description_html
    end
  end

  # Drop any attached description image whose blob no longer appears in the
  # saved HTML (its signed_id is embedded in the rails blob URL). Keeps R2 tidy
  # as the author edits. Purges async so saving stays fast.
  def reconcile_description_images!(html = send(self.class.rich_description_attribute))
    html = html.to_s
    description_images.attachments.each do |attachment|
      attachment.purge_later unless html.include?(attachment.blob.signed_id)
    end
  end
end
