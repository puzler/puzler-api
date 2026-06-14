# frozen_string_literal: true

module Types
  module Enums
    # Cosmetic kind — generated from Cosmetic's `cosmetic_type` enum.
    class CosmeticTypeEnum < BaseEnum
      description "Kind of cosmetic: line, cell_color, shape, or text"
      generate_from_rails_enum Cosmetic.cosmetic_types
    end
  end
end
