module Mutations
  module Play
    class GeneratePlayShareToken < Mutations::BaseMutation
      description "Create or fetch the active share token for a play session (owner only)"

      argument :puzzle_play_id, ID, required: true,
        description: "The play session to share"
      argument :single_use, Boolean, required: false,
        description: "When true, the token locks to the first person who joins"

      field :errors, [ String ], null: false, description: "Validation errors, if any"
      field :share_token, Types::Objects::PuzzlePlayShareTokenType, null: true,
        description: "The active share token for the session"

      def resolve(puzzle_play_id:, single_use: false)
        require_auth!
        play = PuzzlePlay.find_by(id: puzzle_play_id)
        raise GraphQL::ExecutionError, "Play session not found" unless play
        raise GraphQL::ExecutionError, "Not authorized" unless play.user_id == current_user.id

        token = play.share_tokens.shareable.order(created_at: :desc).first
        if token
          token.update!(single_use:) unless token.single_use == single_use
        else
          token = play.share_tokens.create!(created_by: current_user, single_use:)
        end
        { share_token: token, errors: [] }
      end
    end
  end
end
