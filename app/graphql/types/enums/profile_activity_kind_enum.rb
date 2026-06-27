# frozen_string_literal: true

module Types
  module Enums
    # The kind of event in a user's recent public activity feed.
    class ProfileActivityKindEnum < BaseEnum
      description "The kind of event in a profile activity feed"
      value "PUBLISHED_PUZZLE", value: "PUBLISHED_PUZZLE", description: "The user published a puzzle"
      value "REVIEW_WRITTEN", value: "REVIEW_WRITTEN", description: "The user wrote a review on a puzzle"
      value "SOLVE", value: "SOLVE", description: "The user solved a puzzle"
    end
  end
end
