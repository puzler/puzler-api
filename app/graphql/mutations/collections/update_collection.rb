module Mutations
  module Collections
    class UpdateCollection < Mutations::BaseMutation
      description "Update a collection's title, description, visibility, or mode"

      SELECTABLE_VISIBILITY = %w[private unlisted public].freeze
      ALLOWED_MODES = %w[unordered sequence].freeze

      argument :attrs, Types::InputObjects::CollectionAttrsInput, required: true,
        description: "Fields to update"
      argument :id, ID, required: true, description: "ID of the collection"

      field :collection, Types::Objects::CollectionType, null: true, description: "The updated collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(id:, attrs:)
        require_auth!
        collection = current_user.collections.find_by(id:)
        raise GraphQL::ExecutionError, "Collection not found" unless collection

        data = attrs.to_h
        if data[:visibility] && SELECTABLE_VISIBILITY.exclude?(data[:visibility])
          return { collection: nil, errors: [ "Unsupported visibility: #{data[:visibility]}" ] }
        end
        if data[:mode] && ALLOWED_MODES.exclude?(data[:mode])
          return { collection: nil, errors: [ "Unsupported mode: #{data[:mode]}" ] }
        end

        if collection.update(data.compact)
          { collection:, errors: [] }
        else
          { collection: nil, errors: collection.errors.full_messages }
        end
      end
    end
  end
end
