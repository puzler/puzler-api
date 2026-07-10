module Mutations
  module Collections
    # Save the rich page body for a collection (author only). The HTML is
    # sanitized server-side before storage, and orphaned uploaded images are
    # purged so removing an image from the doc cleans up its blob.
    class UpdateCollectionPageDescription < Mutations::BaseMutation
      description "Save the sanitized rich page body for a collection"

      argument :collection_id, ID, required: true, description: "Collection to update"
      argument :html, String, required: true,
        description: "Raw TipTap HTML; sanitized server-side before it is stored"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(collection_id:, html:)
        collection = require_owned!(:collections, "Collection", id: collection_id)

        clean = HtmlSanitizer.sanitize(html, allowed_image_hosts: DescriptionImageHost.allowed)
        if collection.update(page_description_html: clean)
          collection.reconcile_description_images!
          { collection:, errors: [] }
        else
          { collection: nil, errors: collection.errors.full_messages }
        end
      rescue HtmlSanitizer::TooLarge => e
        { collection: nil, errors: [ e.message ] }
      end
    end
  end
end
