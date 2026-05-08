module Types
  module Objects
    class PuzzlePlayType < BaseObject
      description "A player's in-progress or completed session on a puzzle"

      field :cell_state, GraphQL::Types::JSON, null: false,
        description: "Current cell state keyed by cell coordinate"
      field :completed_at, GraphQL::Types::ISO8601DateTime, null: true,
        description: "When the puzzle was solved; null if still in progress"
      field :id, ID, null: false, description: "Unique play session ID"
      field :is_solved, Boolean, null: false, description: "True when the puzzle has been completed"
      field :puzzle, PuzzleType, null: false, description: "The puzzle being played"
      field :started_at, GraphQL::Types::ISO8601DateTime, null: true, description: "When this session was started"
      field :time_elapsed_seconds, Integer, null: true, description: "Total seconds elapsed in this session"
    end
  end
end
