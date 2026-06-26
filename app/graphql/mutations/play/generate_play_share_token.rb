module Mutations
  module Play
    class GeneratePlayShareToken < Mutations::BaseMutation
      description "Create or fetch a play session's active share token. For a guest with no " \
        "server play yet, promotes their local session into a guest-hosted server play."

      argument :puzzle_id, ID, required: false,
        description: "For a guest hosting: the puzzle whose local session to promote to a server play"
      argument :puzzle_play_id, ID, required: false,
        description: "The existing play session to share (logged-in owners)"
      argument :seed, GraphQL::Types::JSON, required: false,
        description: "When a guest promotes a local session: { cellState, progressState } to seed the play"
      argument :single_use, Boolean, required: false,
        description: "When true, the token locks to the first person who joins"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :puzzle_play, Types::Objects::PuzzlePlayType, null: true,
        description: "The (possibly newly-promoted) play session being shared"
      field :share_token, Types::Objects::PuzzlePlayShareTokenType, null: true,
        description: "The active share token for the session"

      def resolve(puzzle_play_id: nil, puzzle_id: nil, single_use: false, seed: nil)
        require_actor!
        play = resolve_or_promote_play(puzzle_play_id:, puzzle_id:, seed:)
        raise GraphQL::ExecutionError, "Play session not found" unless play
        raise GraphQL::ExecutionError, "Not authorized" unless play.owned_by?(current_actor)

        token = play.share_tokens.shareable.order(created_at: :desc).first
        if token
          token.update!(single_use:) unless token.single_use == single_use
        else
          token = play.share_tokens.create!(single_use:, **current_actor.token_created_by_attrs)
        end
        { puzzle_play: play, share_token: token, errors: [] }
      end

      private

      # Logged-in owners share an existing play by id. A guest who is hosting for
      # the first time has no server play, so we create a guest-hosted one for the
      # puzzle, seeded from the client's local snapshot.
      def resolve_or_promote_play(puzzle_play_id:, puzzle_id:, seed:)
        return PuzzlePlay.find_by(id: puzzle_play_id) if puzzle_play_id.present?
        return nil unless current_actor.guest? && puzzle_id.present?

        puzzle = Puzzle.publicly_visible.find_by(id: puzzle_id)
        return nil unless puzzle

        seed ||= {}
        PuzzlePlay.guest_hosted.in_progress.find_by(puzzle:, guest_token: current_actor.guest_token) ||
          PuzzlePlay.create!(
            puzzle:, guest_token: current_actor.guest_token, started_at: Time.current,
            cell_state: seed["cellState"] || {}, progress_state: seed["progressState"] || {}
          )
      end
    end
  end
end
