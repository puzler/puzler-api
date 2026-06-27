module Types
  module Objects
    class CommentType < BaseObject
      description "A comment on a puzzle"

      field :body, String, null: false, description: "Comment text"
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When the comment was posted"
      field :id, ID, null: false, description: "Unique comment ID"
      field :parent_id, ID, null: true, description: "ID of the parent comment if this is a reply"
      field :puzzle, PuzzleType, null: false, description: "The puzzle this comment is on"
      field :replies, [ CommentType ], null: false, description: "Direct replies to this comment"
      field :user, UserType, null: false, description: "User who posted the comment"
    end
  end
end
