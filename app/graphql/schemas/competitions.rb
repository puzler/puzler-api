module Schemas
  module Competitions
    module Queries
      include Types::Interfaces::BaseInterface
      description "Competition queries"
      graphql_name "CompetitionQueries"

      field :competition_leaderboard, [ Types::Objects::CompetitionLeaderboardEntryType ], null: false,
        description: "Final standings for a competition (finalized runs only)" do
        argument :collection_id, ID, required: true, description: "The competition collection"
        argument :share_token, String, required: false, description: "Share token for unlisted collections"
      end

      field :my_active_competition_run, Types::Objects::CompetitionRunType, null: true,
        description: "The viewer's currently active competition run, if any (powers the global bar)"

      def competition_leaderboard(collection_id:, share_token: nil)
        collection = Collection.find_by(id: collection_id)
        return [] unless collection&.viewable_by?(context[:current_user], share_token:)

        finalize_expired!(collection)
        rank(collection.competition_runs.where.not(finalized_at: nil)
                       .order(total_points: :desc, time_used_seconds: :asc).includes(:user))
      end

      def my_active_competition_run(...)
        user = context[:current_user]
        return nil unless user

        CompetitionRun.where(user:, finished_at: nil)
                      .where("deadline >= ?", Time.current - CompetitionRun::GRACE_SECONDS)
                      .order(started_at: :desc).first
      end

      private

      # Lazy finalization: expired-but-unscored runs get frozen the next time
      # anyone looks at the board. No scheduled job required.
      def finalize_expired!(collection)
        collection.competition_runs
                  .where(finalized_at: nil, finished_at: nil)
                  .where("deadline < ?", Time.current - CompetitionRun::GRACE_SECONDS)
                  .find_each(&:finalize!)
      end

      def rank(runs)
        runs.each_with_index.map do |run, index|
          { rank: index + 1, total_points: run.total_points, correct_count: run.correct_count,
            time_used_seconds: run.time_used_seconds,
            username: run.user.username, display_name: run.user.display_name }
        end
      end
    end

    module Mutations
      include Types::Interfaces::BaseInterface
      description "Competition mutations"
      graphql_name "CompetitionMutations"

      field :finish_competition_run, mutation: ::Mutations::Competitions::FinishCompetitionRun,
        description: "End your run and get your score"
      field :start_competition_run, mutation: ::Mutations::Competitions::StartCompetitionRun,
        description: "Start your single timed attempt"
      field :submit_competition_entry, mutation: ::Mutations::Competitions::SubmitCompetitionEntry,
        description: "Submit a board within your run"
    end
  end
end
