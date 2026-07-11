module Mutations
  module Competitions
    # Start the viewer's one-and-only run on a competition. The deadline is
    # frozen here (now + the collection's current limit), so later config edits
    # can't move a live run's goalposts. Idempotent while the run is active
    # (resuming from another device returns the same run); a second start after
    # the run ends is refused.
    class StartCompetitionRun < Mutations::BaseMutation
      description "Start (or resume) your single timed attempt at a competition"

      argument :collection_id, ID, required: true, description: "The competition collection"
      argument :share_token, String, required: false,
        description: "Share token, when the collection was reached by link"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :run, Types::Objects::CompetitionRunType, null: true, description: "The viewer's run"

      def resolve(collection_id:, share_token: nil)
        require_auth!
        collection = Collection.find_by(id: collection_id)
        unless collection&.viewable_by?(current_user, share_token:) && collection.kind_competition?
          return failure("Competition not found")
        end
        return failure("This competition has no time limit yet") if collection.time_limit_seconds.blank?
        return failure("Authors cannot compete in their own collection") if author_or_admin?(collection)

        { run: find_or_start_run(collection), errors: [] }
      rescue GraphQL::ExecutionError
        raise
      rescue StandardError => e
        failure(e.message)
      end

      private

      def find_or_start_run(collection)
        existing = collection.competition_runs.find_by(user: current_user)
        if existing
          raise "You have already competed in this collection" if existing.ended?

          return existing
        end

        now = Time.current
        collection.competition_runs.create!(
          user: current_user, started_at: now, deadline: now + collection.time_limit_seconds
        )
      rescue ActiveRecord::RecordNotUnique
        # Double-click race: the other request won; return its run.
        collection.competition_runs.find_by!(user: current_user)
      end

      def author_or_admin?(collection)
        current_user.id == collection.author_id || current_user.admin?
      end

      def failure(message)
        { run: nil, errors: [ message ] }
      end
    end
  end
end
