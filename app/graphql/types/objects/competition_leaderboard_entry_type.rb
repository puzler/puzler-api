module Types
  module Objects
    class CompetitionLeaderboardEntryType < BaseObject
      description "One solver's standing in a competition"

      field :correct_count, Integer, null: false, description: "Puzzles solved correctly"
      field :display_name, String, null: false, description: "The solver's display name (shown in the UI)"
      field :rank, Integer, null: false, description: "1-based position (highest score first, faster time breaks ties)"
      field :time_used_seconds, Integer, null: false, description: "How long their run lasted"
      field :total_points, Integer, null: false, description: "Final score"
      field :username, String, null: false, description: "The solver's unique handle (for linking to their profile)"
    end
  end
end
