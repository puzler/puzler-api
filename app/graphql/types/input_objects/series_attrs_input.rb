module Types
  module InputObjects
    class SeriesAttrsInput < BaseInputObject
      description "Fields that can be updated on a series"

      argument :description, String, required: false, description: "Optional description"
      argument :title, String, required: false, description: "Series title"
      argument :visibility, String, required: false, description: "private, unlisted, or public"
    end
  end
end
