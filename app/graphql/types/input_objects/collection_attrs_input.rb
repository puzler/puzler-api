module Types
  module InputObjects
    class CollectionAttrsInput < BaseInputObject
      description "Fields that can be updated on a collection"

      argument :description, String, required: false, description: "Optional description"
      argument :mode, Types::Enums::CollectionModeEnum, required: false, description: "Ordering mode: unordered or sequence"
      argument :timed, Boolean, required: false, description: "Competition timing on/off"
      argument :title, String, required: false, description: "Collection title"
      argument :visibility, Types::Enums::CollectionVisibilityEnum, required: false,
        description: "private, unlisted, public, or containers_only"
    end
  end
end
