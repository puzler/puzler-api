module Mutations
  module Competitions
    # Finish early (or acknowledge an expired run): stamps the finish, computes
    # and freezes the score, and returns the finalized run.
    class FinishCompetitionRun < Mutations::BaseMutation
      description "End your competition run and get your final score"

      argument :collection_id, ID, required: true, description: "The competition collection"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :run, Types::Objects::CompetitionRunType, null: true, description: "The finalized run"

      def resolve(collection_id:)
        require_auth!
        run = CompetitionRun.find_by(collection_id:, user: current_user)
        return { run: nil, errors: [ "You have no run on this competition" ] } unless run

        run.update!(finished_at: [ Time.current, run.deadline ].min) if run.finished_at.nil?
        { run: run.finalize!, errors: [] }
      end
    end
  end
end
