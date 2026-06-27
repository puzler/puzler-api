# frozen_string_literal: true

module Types
  module Enums
    # How much of a user's solving activity their public profile reveals —
    # generated from User's `solve_history_visibility` enum. Escalating: HIDDEN <
    # COUNT < PUZZLES < DETAILED.
    class SolveHistoryVisibilityEnum < BaseEnum
      description "How much of a user's solving activity their public profile reveals"
      generate_from_rails_enum User.solve_history_visibilities
    end
  end
end
