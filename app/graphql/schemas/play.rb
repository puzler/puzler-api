module Schemas
  module Play
    module Mutations
      include Types::Interfaces::BaseInterface
      description "Mutations for playing puzzles"
      graphql_name "PlayMutations"

      field :save_progress, mutation: ::Mutations::Play::SaveProgress,
        description: "Persist the current cell state for an in-progress session"
      field :start_play, mutation: ::Mutations::Play::StartPlay,
        description: "Start or resume a play session for a published puzzle"
      field :submit_solution, mutation: ::Mutations::Play::SubmitSolution,
        description: "Submit a completed solution for server-side validation"
    end
  end
end
