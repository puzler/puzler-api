# frozen_string_literal: true

module Types
  module Enums
    # Curated accent color for a collection page — generated from Collection's
    # `accent_color` enum.
    class CollectionAccentColorEnum < BaseEnum
      description "Curated accent color for a collection page"
      generate_from_rails_enum Collection.accent_colors
    end
  end
end
