module Mutations
  module Collections
    class ScheduleCollectionRelease < Mutations::BaseMutation
      description "Schedule (or clear) a collection's release moment. Until it passes, the " \
                  "collection is invisible to everyone but the author; release is evaluated " \
                  "on read — no job runs."

      argument :id, ID, required: true, description: "ID of the collection"
      argument :released_at, GraphQL::Types::ISO8601DateTime, required: false,
        description: "When the collection becomes available; null releases immediately"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(id:, released_at: nil)
        collection = require_owned!(:collections, "Collection", id:)

        if collection.update(released_at:)
          { collection:, errors: [] }
        else
          { collection: nil, errors: collection.errors.full_messages }
        end
      end
    end
  end
end
