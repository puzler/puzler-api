module Mutations
  module Collections
    class UpdateCollection < Mutations::BaseMutation
      description "Update a collection's title, description, visibility, mode, kind, or competition terms"

      SELECTABLE_VISIBILITY = %w[private unlisted public containers_only].freeze
      ALLOWED_MODES = %w[unordered sequence].freeze
      ALLOWED_KINDS = %w[basic hunt competition].freeze
      # The contest terms; frozen once anyone has competed (kind included).
      COMPETITION_TERMS = %i[kind time_limit_seconds submission_policy penalty_points
                             bonus_points_per_minute clamp_score_at_zero enforced_settings].freeze

      argument :attrs, Types::InputObjects::CollectionAttrsInput, required: true,
        description: "Fields to update"
      argument :competition_config, Types::InputObjects::CompetitionConfigInput, required: false,
        description: "Competition contest terms to update"
      argument :id, ID, required: true, description: "ID of the collection"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(id:, attrs:, competition_config: nil)
        collection = require_owned!(:collections, "Collection", id:)

        data = attrs.to_h.compact.merge(competition_config ? competition_config.to_h : {})
        error = validate(collection, data)
        return { collection: nil, errors: [ error ] } if error

        if collection.update(data)
          { collection:, errors: [] }
        else
          { collection: nil, errors: collection.errors.full_messages }
        end
      end

      private

      def validate(collection, data)
        return "Unsupported visibility: #{data[:visibility]}" if
          data[:visibility] && SELECTABLE_VISIBILITY.exclude?(data[:visibility])
        return "Unsupported mode: #{data[:mode]}" if data[:mode] && ALLOWED_MODES.exclude?(data[:mode])
        return "Unsupported kind: #{data[:kind]}" if data[:kind] && ALLOWED_KINDS.exclude?(data[:kind])

        if collection.competition_locked? && data.keys.intersect?(COMPETITION_TERMS)
          return "The contest terms are locked: someone has already competed"
        end

        nil
      end
    end
  end
end
