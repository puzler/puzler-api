module Types
  module InputObjects
    # The owner-controlled visibility preferences for a user's public profile.
    # Every field is optional so a single toggle can be saved without resending
    # the rest.
    class ProfileVisibilityInput < BaseInputObject
      description "Public-profile visibility preferences"

      argument :show_activity, Boolean, required: false,
        description: "Show the recent activity feed"
      argument :show_favorites, Boolean, required: false,
        description: "Show the favorited puzzles tab"
      argument :show_stats, Boolean, required: false,
        description: "Show the aggregate stats panel"
      argument :show_subscriptions, Boolean, required: false,
        description: "Show the subscribed series tab"
      argument :solve_history_visibility, Types::Enums::SolveHistoryVisibilityEnum, required: false,
        description: "How much solving activity the profile reveals"
    end
  end
end
