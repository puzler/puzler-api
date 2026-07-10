module Mutations
  module Collections
    # Create a story page and append it to a collection as an entry. The body
    # starts empty; the author writes it via updateStoryPage (autosaving editor).
    class AddStoryPageToCollection < Mutations::BaseMutation
      description "Create a story page at the end of a collection"

      argument :collection_id, ID, required: true, description: "Target collection"
      argument :title, String, required: false, description: "Optional heading for the story page"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :story_page, Types::Objects::StoryPageType, null: true, description: "The new story page"

      def resolve(collection_id:, title: nil)
        collection = require_owned!(:collections, "Collection", id: collection_id)

        story_page = StoryPage.new(author: current_user, title:)
        unless story_page.save
          return { collection: nil, story_page: nil, errors: story_page.errors.full_messages }
        end

        next_position = (collection.entries.maximum(:position) || -1) + 1
        collection.entries.create!(entryable: story_page, position: next_position)
        { collection: collection.reload, story_page:, errors: [] }
      end
    end
  end
end
