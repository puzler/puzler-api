module Mutations
  module Play
    class StartPlay < Mutations::BaseMutation
      description "Start or resume a play session for a published puzzle"

      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle to play"

      field :errors, [ String ], null: false,
        description: "Validation errors, if any"
      field :puzzle_play, Types::Objects::PuzzlePlayType, null: true,
        description: "The new or existing unsolved play session"

      def resolve(puzzle_id:)
        puzzle = Puzzle.published_or_featured.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        play = if current_user
          current_user.puzzle_plays.find_or_create_by(puzzle:, is_solved: false) do |p|
            p.started_at = Time.current
          end
        else
          PuzzlePlay.create!(puzzle:, started_at: Time.current)
        end

        { puzzle_play: play, errors: [] }
      end
    end
  end
end
