module Schemas
  module Play
    module Mutations
      include Types::Interfaces::BaseInterface
      description "Mutations for playing puzzles"
      graphql_name "PlayMutations"

      field :check_solution, mutation: ::Mutations::Play::CheckSolution,
        description: "Check an in-progress board, returning solved / correct-so-far / incorrect"
      field :reveal_solve_message, mutation: ::Mutations::Play::RevealSolveMessage,
        description: "Reveal a puzzle's custom solve message for a correct solution"
      field :save_progress, mutation: ::Mutations::Play::SaveProgress,
        description: "Persist the current cell state for an in-progress session"
      field :start_play, mutation: ::Mutations::Play::StartPlay,
        description: "Start or resume a play session for a published puzzle"
      field :submit_solution, mutation: ::Mutations::Play::SubmitSolution,
        description: "Submit a completed solution for server-side validation"
    end
  end
end
