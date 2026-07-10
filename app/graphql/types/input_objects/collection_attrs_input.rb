module Types
  module InputObjects
    class CollectionAttrsInput < BaseInputObject
      description "Fields that can be updated on a collection"

      argument :accent_color, Types::Enums::CollectionAccentColorEnum, required: false,
        description: "Curated accent color for the collection page"
      argument :bg_treatment, Types::Enums::CollectionBgTreatmentEnum, required: false,
        description: "Curated background treatment for the collection page"
      argument :description, String, required: false, description: "Optional description"
      argument :mode, Types::Enums::CollectionModeEnum, required: false, description: "Ordering mode: unordered or sequence"
      argument :timed, Boolean, required: false, description: "Competition timing on/off"
      argument :title, String, required: false, description: "Collection title"
      argument :title_font, Types::Enums::CollectionTitleFontEnum, required: false,
        description: "Curated display font for the collection page title"
      argument :visibility, Types::Enums::CollectionVisibilityEnum, required: false,
        description: "private, unlisted, public, or containers_only"
    end
  end
end
