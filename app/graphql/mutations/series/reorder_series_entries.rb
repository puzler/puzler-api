module Mutations
  module Series
    class ReorderSeriesEntries < Mutations::BaseMutation
      description "Set the order of entries in a series"

      argument :ordered_entry_ids, [ ID ], required: true,
        description: "Entry IDs in the desired order; sets each position by its index"
      argument :series_id, ID, required: true, description: "The series"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :series, Types::Objects::SeriesType, null: true, description: "The reordered series"

      def resolve(series_id:, ordered_entry_ids:)
        series = require_owned!(:series, "Series", id: series_id)

        ordered_entry_ids.each_with_index do |entry_id, index|
          series.series_entries.where(id: entry_id).update_all(position: index)
        end

        { series: series.reload, errors: [] }
      end
    end
  end
end
