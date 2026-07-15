module Schemas
  module Social
    module Mutations
      include Types::Interfaces::BaseInterface
      description "Social interaction mutations"
      graphql_name "SocialMutations"

      field :create_comment, mutation: ::Mutations::Social::CreateComment,
        description: "Post a comment on a published puzzle"
      field :delete_comment, mutation: ::Mutations::Social::DeleteComment,
        description: "Delete a comment posted by the current user"
      field :rate_puzzle, mutation: ::Mutations::Social::RatePuzzle,
        description: "Rate a puzzle or cast a difficulty vote"
      field :set_comment_spoiler, mutation: ::Mutations::Social::SetCommentSpoiler,
        description: "Mark or unmark a comment as a spoiler"
      field :toggle_favorite, mutation: ::Mutations::Social::ToggleFavorite,
        description: "Add or remove a puzzle from the current user's favorites"
    end
  end
end
