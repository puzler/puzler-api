# frozen_string_literal: true

module Types
  module Enums
    # Published-date window for the archive's time-range facet.
    class TimeRangeEnum < BaseEnum
      description "How recently a puzzle was published"
      value "THIS_WEEK", value: "THIS_WEEK", description: "Published in the last week"
      value "THIS_MONTH", value: "THIS_MONTH", description: "Published in the last month"
      value "THIS_YEAR", value: "THIS_YEAR", description: "Published in the last year"
      value "ALL_TIME", value: "ALL_TIME", description: "Any time"
    end
  end
end
