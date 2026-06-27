module Types
  module Objects
    # The owner-controlled visibility preferences for a user's public profile.
    # Public-readable so the client knows which tabs/sections to render; the
    # backend independently enforces each gate. Resolved from the User itself.
    class ProfileVisibilityType < BaseObject
      description "A user's public-profile visibility preferences"

      field :activity, Boolean, null: false, method: :show_activity,
        description: "Whether the activity feed is shown"
      field :favorites, Boolean, null: false, method: :show_favorites,
        description: "Whether favorited puzzles are shown"
      field :solve_history, Types::Enums::SolveHistoryVisibilityEnum, null: false,
        method: :solve_history_visibility, description: "How much solving activity the profile reveals"
      field :stats, Boolean, null: false, method: :show_stats,
        description: "Whether the aggregate stats panel is shown"
      field :subscriptions, Boolean, null: false, method: :show_subscriptions,
        description: "Whether subscribed series are shown"
    end
  end
end
