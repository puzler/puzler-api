module Mutations
  module Series
    class CreateSeries < Mutations::BaseMutation
      description "Create a series"

      SELECTABLE_VISIBILITY = %w[private unlisted public].freeze

      argument :description, String, required: false, description: "Optional description"
      argument :title, String, required: true, description: "Series title"
      argument :visibility, Types::Enums::SeriesVisibilityEnum, required: false, description: "private, unlisted, or public"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :series, Types::Objects::SeriesType, null: true, description: "The new series"

      def resolve(title:, description: nil, visibility: nil)
        require_auth!
        if visibility && SELECTABLE_VISIBILITY.exclude?(visibility)
          return { series: nil, errors: [ "Unsupported visibility: #{visibility}" ] }
        end

        attrs = { title:, description:, visibility: }.compact
        series = current_user.series.build(attrs)

        if series.save
          { series:, errors: [] }
        else
          { series: nil, errors: series.errors.full_messages }
        end
      end
    end
  end
end
