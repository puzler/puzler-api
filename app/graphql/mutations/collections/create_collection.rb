module Mutations
  module Collections
    class CreateCollection < Mutations::BaseMutation
      description "Create a collection"

      SELECTABLE_VISIBILITY = %w[private unlisted public containers_only].freeze
      ALLOWED_MODES = %w[unordered sequence].freeze

      argument :description, String, required: false, description: "Optional description"
      argument :mode, Types::Enums::CollectionModeEnum, required: false, description: "Ordering mode: unordered or sequence"
      argument :title, String, required: true, description: "Collection title"
      argument :visibility, Types::Enums::CollectionVisibilityEnum, required: false,
        description: "private, unlisted, public, or containers_only"

      field :collection, Types::Objects::CollectionType, null: true, description: "The new collection"
      field :errors, [ String ], null: false, description: "Validation errors, if any"

      def resolve(title:, description: nil, visibility: nil, mode: nil)
        require_auth!
        if visibility && SELECTABLE_VISIBILITY.exclude?(visibility)
          return { collection: nil, errors: [ "Unsupported visibility: #{visibility}" ] }
        end
        if mode && ALLOWED_MODES.exclude?(mode)
          return { collection: nil, errors: [ "Unsupported mode: #{mode}" ] }
        end

        attrs = { title:, description:, visibility:, mode: }.compact
        collection = current_user.collections.build(attrs)

        if collection.save
          { collection:, errors: [] }
        else
          { collection: nil, errors: collection.errors.full_messages }
        end
      end
    end
  end
end
