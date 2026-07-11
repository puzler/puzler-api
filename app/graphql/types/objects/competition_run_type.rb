module Types
  module Objects
    # The viewer's own competition run. secondsRemaining is the client's only
    # clock anchor (the server is the referee); score fields stay nil until the
    # run is finalized so nothing leaks mid-run.
    class CompetitionRunType < BaseObject
      description "The viewer's timed attempt at a competition collection"

      field :base_points, Integer, null: true, description: "Points from correct puzzles; nil until finalized"
      field :bonus_points, Integer, null: true, description: "Time bonus; nil until finalized"
      field :collection, CollectionType, null: false, description: "The competition this run belongs to"
      field :correct_count, Integer, null: true, description: "Correct puzzles; nil until finalized"
      field :deadline, GraphQL::Types::ISO8601DateTime, null: false, description: "When the run ends"
      field :finalized, Boolean, null: false, method: :final?,
        description: "Whether the score is computed and frozen"
      field :finished_at, GraphQL::Types::ISO8601DateTime, null: true,
        description: "When the solver finished early; null if they ran the clock"
      field :id, ID, null: false, description: "Unique run ID"
      field :penalty_points, Integer, null: true, description: "Points lost to penalties; nil until finalized"
      field :seconds_remaining, Integer, null: false,
        description: "Server-computed seconds left on the clock (0 when over) — anchor countdowns to this"
      field :started_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When the run started"
      field :submissions, [ CompetitionSubmissionType ], null: false,
        description: "The viewer's per-puzzle submission states"
      field :time_used_seconds, Integer, null: true, description: "Scored run length; nil until finalized"
      field :total_points, Integer, null: true, description: "Final score; nil until finalized"

      %i[base_points bonus_points correct_count penalty_points time_used_seconds total_points].each do |name|
        define_method(name) { object.public_send(name) if object.final? }
      end
    end
  end
end
