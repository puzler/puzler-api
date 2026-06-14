module Mutations
  module Series
    class ScheduleSeriesEntry < Mutations::BaseMutation
      description "Set or clear the scheduled release time of a series entry"

      argument :entry_id, ID, required: true, description: "ID of the series entry"
      argument :released_at, GraphQL::Types::ISO8601DateTime, required: false,
        description: "When the entry should release; omit/null to release immediately"

      field :entry, Types::Objects::SeriesEntryType, null: true, description: "The updated entry"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(entry_id:, released_at: nil)
        require_auth!
        entry = SeriesEntry.find_by(id: entry_id)
        raise GraphQL::ExecutionError, "Entry not found" unless entry
        raise GraphQL::ExecutionError, "Entry not found" unless current_user.series.exists?(id: entry.series_id)

        entry.update(released_at:)
        { entry:, errors: [] }
      end
    end
  end
end
