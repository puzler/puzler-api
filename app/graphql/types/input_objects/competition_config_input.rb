module Types
  module InputObjects
    class CompetitionConfigInput < BaseInputObject
      description "Competition contest terms; omitted fields are left untouched"

      argument :bonus_points_per_minute, Integer, required: false,
        description: "Bonus per whole minute remaining when every puzzle is solved"
      argument :clamp_score_at_zero, Boolean, required: false,
        description: "Floor the total score at zero (off allows negative scores)"
      argument :enforced_settings, GraphQL::Types::JSON, required: false,
        description: "Player settings to enforce (key => bool); absent keys stay the solver's choice"
      argument :penalty_points, Integer, required: false,
        description: "Points lost per incorrect submission"
      argument :show_entry_points, Boolean, required: false,
        description: "Whether solvers see each puzzle's point value"
      argument :submission_policy, Types::Enums::CompetitionSubmissionPolicyEnum, required: false,
        description: "blind, instant, or single"
      argument :time_limit_seconds, Integer, required: false,
        description: "Run length in seconds"
    end
  end
end
