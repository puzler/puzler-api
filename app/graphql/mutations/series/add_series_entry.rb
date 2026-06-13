module Mutations
  module Series
    class AddSeriesEntry < Mutations::BaseMutation
      description "Add one of your puzzles or collections to the end of a series"

      ENTRY_TYPES = %w[Puzzle Collection].freeze

      argument :entryable_id, ID, required: true, description: "ID of the puzzle or collection to add"
      argument :entryable_type, String, required: true, description: "Puzzle or Collection"
      argument :series_id, ID, required: true, description: "Target series"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :series, Types::Objects::SeriesType, null: true, description: "The updated series"

      def resolve(series_id:, entryable_type:, entryable_id:)
        require_auth!
        if ENTRY_TYPES.exclude?(entryable_type)
          return { series: nil, errors: [ "Unsupported entry type: #{entryable_type}" ] }
        end

        series = current_user.series.find_by(id: series_id)
        raise GraphQL::ExecutionError, "Series not found" unless series

        entryable = author_owned(entryable_type, entryable_id)
        raise GraphQL::ExecutionError, "#{entryable_type} not found" unless entryable

        unless series.series_entries.exists?(entryable_type:, entryable_id: entryable.id)
          next_position = (series.series_entries.maximum(:position) || -1) + 1
          series.series_entries.create!(entryable:, position: next_position)
        end

        { series: series.reload, errors: [] }
      end

      private

      # Only the author's own puzzles/collections can be added to their series.
      def author_owned(type, id)
        case type
        when "Puzzle" then current_user.puzzles.find_by(id:)
        when "Collection" then current_user.collections.find_by(id:)
        end
      end
    end
  end
end
