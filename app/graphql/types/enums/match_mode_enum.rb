# frozen_string_literal: true

module Types
  module Enums
    # How a multi-value constraint filter combines: ANY (overlap) or ALL (contains).
    class MatchModeEnum < BaseEnum
      description "How to combine multiple constraint filters: ANY (at least one) or ALL (every one)"
      value "ANY", value: "ANY", description: "Match records using at least one of the selected constraints"
      value "ALL", value: "ALL", description: "Match records using every selected constraint"
    end
  end
end
