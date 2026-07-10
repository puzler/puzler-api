# frozen_string_literal: true

module Types
  module Enums
    # Curated background treatment for a collection page — generated from
    # Collection's `bg_treatment` enum.
    class CollectionBgTreatmentEnum < BaseEnum
      description "Curated background treatment for a collection page"
      generate_from_rails_enum Collection.bg_treatments
    end
  end
end
