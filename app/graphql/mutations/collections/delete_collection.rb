module Mutations
  module Collections
    class DeleteCollection < Mutations::BaseMutation
      description "Delete a collection; the puzzles themselves are untouched"

      argument :id, ID, required: true, description: "ID of the collection to delete"

      field :errors, [ String ], null: false, description: "Errors, if any"
      field :success, Boolean, null: false, description: "Whether the collection was deleted"

      def resolve(id:)
        require_auth!
        collection = current_user.collections.find_by(id:)
        raise GraphQL::ExecutionError, "Collection not found" unless collection

        collection.destroy
        { success: true, errors: [] }
      end
    end
  end
end
