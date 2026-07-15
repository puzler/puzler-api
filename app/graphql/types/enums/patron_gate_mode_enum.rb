# frozen_string_literal: true

module Types
  module Enums
    class PatronGateModeEnum < BaseEnum
      description "How a patron gate decides who qualifies: minimum tier (with pledge-amount " \
                  "fallback), an explicit tier list, or a minimum pledge amount"
      generate_from_rails_enum PatronGate.modes
    end
  end
end
