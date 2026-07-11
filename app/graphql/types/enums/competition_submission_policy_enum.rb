# frozen_string_literal: true

module Types
  module Enums
    # How competition submissions behave — generated from Collection's
    # `submission_policy` enum.
    class CompetitionSubmissionPolicyEnum < BaseEnum
      description "blind (no verdict, resubmit freely, last counts), instant (verdict + per-wrong penalty), or single (one shot per puzzle)"
      generate_from_rails_enum Collection.submission_policies
    end
  end
end
