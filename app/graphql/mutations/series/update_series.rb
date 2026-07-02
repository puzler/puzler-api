module Mutations
  module Series
    class UpdateSeries < Mutations::BaseMutation
      description "Update a series' title, description, or visibility"

      SELECTABLE_VISIBILITY = %w[private unlisted public].freeze

      argument :attrs, Types::InputObjects::SeriesAttrsInput, required: true,
        description: "Fields to update"
      argument :id, ID, required: true, description: "ID of the series"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :series, Types::Objects::SeriesType, null: true, description: "The updated series"

      def resolve(id:, attrs:)
        series = require_owned!(:series, "Series", id:)

        data = attrs.to_h
        if data[:visibility] && SELECTABLE_VISIBILITY.exclude?(data[:visibility])
          return { series: nil, errors: [ "Unsupported visibility: #{data[:visibility]}" ] }
        end

        if series.update(data.compact)
          { series:, errors: [] }
        else
          { series: nil, errors: series.errors.full_messages }
        end
      end
    end
  end
end
