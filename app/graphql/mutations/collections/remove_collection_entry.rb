module Mutations
  module Collections
    # Remove one entry from a collection. A puzzle entry just unlinks (the
    # puzzle is untouched); a story page exists only for its collection, so
    # removing its entry destroys the page and its images too.
    class RemoveCollectionEntry < Mutations::BaseMutation
      description "Remove an entry from a collection (story pages are deleted with it)"

      argument :collection_id, ID, required: true, description: "The collection"
      argument :entry_id, ID, required: true, description: "Entry to remove"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(collection_id:, entry_id:)
        collection = require_owned!(:collections, "Collection", id: collection_id)

        entry = collection.entries.find_by(id: entry_id)
        if entry
          was_puzzle = entry.entryable_type == "Puzzle"
          was_puzzle ? entry.destroy! : entry.entryable.destroy!
          collection.recompute_aggregates! if was_puzzle
        end

        { collection: collection.reload, errors: [] }
      end
    end
  end
end
