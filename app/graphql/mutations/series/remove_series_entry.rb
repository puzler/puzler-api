module Mutations
  module Series
    class RemoveSeriesEntry < Mutations::BaseMutation
      description "Remove an entry from a series"

      argument :entry_id, ID, required: true, description: "ID of the series entry to remove"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :series, Types::Objects::SeriesType, null: true, description: "The updated series"

      def resolve(entry_id:)
        require_auth!
        entry = SeriesEntry.find_by(id: entry_id)
        raise GraphQL::ExecutionError, "Entry not found" unless entry

        series = require_owned!(:series, "Entry", id: entry.series_id)

        entry.destroy
        series.recompute_aggregates!
        { series: series.reload, errors: [] }
      end
    end
  end
end
