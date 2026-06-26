module Schemas
  module Play
    module Mutations
      include Types::Interfaces::BaseInterface
      description "Mutations for playing puzzles"
      graphql_name "PlayMutations"

      field :check_solution, mutation: ::Mutations::Play::CheckSolution,
        description: "Check an in-progress board, returning solved / correct-so-far / incorrect"
      field :generate_play_share_token, mutation: ::Mutations::Play::GeneratePlayShareToken,
        description: "Create or fetch the active share token for a play session (owner only)"
      field :join_play_session, mutation: ::Mutations::Play::JoinPlaySession,
        description: "Join a shared play session via its share token"
      field :kick_participant, mutation: ::Mutations::Play::KickParticipant,
        description: "Remove a collaborator from a play session (host only)"
      field :reveal_solve_message, mutation: ::Mutations::Play::RevealSolveMessage,
        description: "Reveal a puzzle's custom solve message for a correct solution"
      field :revoke_play_session, mutation: ::Mutations::Play::RevokePlaySession,
        description: "Stop sharing a play session and remove collaborators (owner only)"
      field :save_progress, mutation: ::Mutations::Play::SaveProgress,
        description: "Persist the current cell state for an in-progress session"
      field :start_play, mutation: ::Mutations::Play::StartPlay,
        description: "Start or resume a play session for a published puzzle"
      field :submit_solution, mutation: ::Mutations::Play::SubmitSolution,
        description: "Submit a completed solution for server-side validation"
    end
  end
end
