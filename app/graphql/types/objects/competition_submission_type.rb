module Types
  module Objects
    # A solver's submission state for one puzzle in their run. This type is the
    # blind-policy choke point: the verdict and attempt counts are nil under
    # blind until the run is finalized, so nothing the client receives reveals
    # correctness mid-run.
    class CompetitionSubmissionType < BaseObject
      description "The viewer's submission state for one puzzle in a competition run"

      field :correct, Boolean, null: true,
        description: "The verdict; nil under the blind policy until the run is finalized"
      field :puzzle_id, ID, null: false, description: "The submitted puzzle"
      field :submitted_at, GraphQL::Types::ISO8601DateTime, null: false,
        description: "When the latest submission landed"
      field :wrong_attempts, Integer, null: true,
        description: "Incorrect submissions so far; nil under the blind policy until finalized"

      def correct
        object.correct if reveal?
      end

      def wrong_attempts
        object.wrong_attempts if reveal?
      end

      private

      def reveal?
        run = object.competition_run
        !run.collection.policy_blind? || run.final?
      end
    end
  end
end
