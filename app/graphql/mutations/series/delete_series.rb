module Mutations
  module Series
    class DeleteSeries < Mutations::BaseMutation
      description "Delete a series (its entries are removed; the puzzles and collections are kept)"

      argument :id, ID, required: true, description: "ID of the series to delete"

      field :deleted_id, ID, null: true, description: "ID of the deleted series"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(id:)
        require_auth!
        series = current_user.series.find_by(id:)
        raise GraphQL::ExecutionError, "Series not found" unless series

        series.destroy
        { deleted_id: id, errors: [] }
      end
    end
  end
end
