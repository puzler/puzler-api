module Mutations
  module Collections
    # Update a story page's title and/or body (author only). The HTML is
    # sanitized server-side before storage, and orphaned uploaded images are
    # purged so removing an image from the doc cleans up its blob.
    class UpdateStoryPage < Mutations::BaseMutation
      description "Update a story page's title or sanitized rich body"

      argument :html, String, required: false,
        description: "Raw TipTap HTML; sanitized server-side before it is stored"
      argument :id, ID, required: true, description: "Story page to update"
      argument :title, String, required: false, description: "New heading; empty clears it"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :story_page, Types::Objects::StoryPageType, null: true, description: "The updated story page"

      def resolve(id:, html: nil, title: nil)
        story_page = require_owned!(:story_pages, "Story page", id:)

        attrs = {}
        attrs[:title] = title.presence unless title.nil?
        unless html.nil?
          attrs[:body_html] = HtmlSanitizer.sanitize(html, allowed_image_hosts: DescriptionImageHost.allowed)
        end

        if story_page.update(attrs)
          story_page.reconcile_description_images! if attrs.key?(:body_html)
          { story_page:, errors: [] }
        else
          { story_page: nil, errors: story_page.errors.full_messages }
        end
      rescue HtmlSanitizer::TooLarge => e
        { story_page: nil, errors: [ e.message ] }
      end
    end
  end
end
