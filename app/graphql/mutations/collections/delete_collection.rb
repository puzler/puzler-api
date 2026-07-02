module Mutations
  module Collections
    class DeleteCollection < Mutations::BaseMutation
      description "Delete a collection; the puzzles themselves are untouched"

      argument :id, ID, required: true, description: "ID of the collection to delete"

      field :errors, [ String ], null: false, description: "Errors, if any"
      field :success, Boolean, null: false, description: "Whether the collection was deleted"

      def resolve(id:)
        collection = require_owned!(:collections, "Collection", id:)

        collection.destroy
        { success: true, errors: [] }
      end
    end
  end
end
