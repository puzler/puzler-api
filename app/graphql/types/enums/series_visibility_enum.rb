# frozen_string_literal: true

module Types
  module Enums
    # Access mode for a series — generated from Series' `visibility` enum.
    class SeriesVisibilityEnum < BaseEnum
      description "Who can see a series: private, unlisted, public, or the patron/subscriber tiers"
      generate_from_rails_enum Series.visibilities
    end
  end
end
