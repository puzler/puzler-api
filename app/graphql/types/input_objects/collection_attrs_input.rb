module Types
  module InputObjects
    class CollectionAttrsInput < BaseInputObject
      description "Fields that can be updated on a collection"

      argument :description, String, required: false, description: "Optional description"
      argument :mode, String, required: false, description: "Ordering mode: unordered or sequence"
      argument :title, String, required: false, description: "Collection title"
      argument :visibility, String, required: false, description: "private, unlisted, or public"
    end
  end
end
