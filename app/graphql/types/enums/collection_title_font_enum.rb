# frozen_string_literal: true

module Types
  module Enums
    # Curated display font for a collection page title — generated from
    # Collection's `title_font` enum.
    class CollectionTitleFontEnum < BaseEnum
      description "Curated display font for a collection page title"
      generate_from_rails_enum Collection.title_fonts
    end
  end
end
