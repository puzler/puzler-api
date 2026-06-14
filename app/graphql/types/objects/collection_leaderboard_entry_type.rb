module Types
  module Objects
    class CollectionLeaderboardEntryType < BaseObject
      description "One solver's standing in a timed collection"

      field :display_name, String, null: false, description: "The solver's display name (shown in the UI)"
      field :rank, Integer, null: false, description: "1-based position (fastest first)"
      field :total_seconds, Integer, null: false, description: "Sum of best times across all puzzles"
      field :username, String, null: false, description: "The solver's unique handle (for linking to their profile)"
    end
  end
end
