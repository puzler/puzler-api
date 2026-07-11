module Types
  module Objects
    # A competition collection's contest terms. World-readable: entrants must
    # see the rules before they start, and nothing here is secret.
    class CompetitionConfigType < BaseObject
      description "The contest terms of a competition collection"

      field :bonus_points_per_minute, Integer, null: false,
        description: "Bonus per whole minute remaining when every puzzle is solved"
      field :clamp_score_at_zero, Boolean, null: false,
        description: "Whether the total score is floored at zero"
      field :enforced_settings, GraphQL::Types::JSON, null: false,
        description: "Player settings the author enforces (key => bool); absent keys are the solver's choice"
      field :locked, Boolean, null: false, method: :competition_locked?,
        description: "Whether the terms are frozen because someone has already competed"
      field :penalty_points, Integer, null: false,
        description: "Points lost per incorrect submission (per the submission policy)"
      field :submission_policy, Types::Enums::CompetitionSubmissionPolicyEnum, null: false,
        description: "How submissions behave: blind, instant, or single"
      field :time_limit_seconds, Integer, null: true,
        description: "The run length; null while the author hasn't set one (competition can't start)"
    end
  end
end
