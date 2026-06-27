module Types
  module Objects
    class CommentType < BaseObject
      description "A comment on a puzzle"

      field :body, String, null: false, description: "Comment text"
      field :commenter_solved, Boolean, null: false,
        description: "Whether the commenter has completed this puzzle (drives the 'solved' badge)"
      field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When the comment was posted"
      field :id, ID, null: false, description: "Unique comment ID"
      field :is_author, Boolean, null: false,
        description: "Whether the commenter is the puzzle's author"
      field :parent_id, ID, null: true, description: "ID of the parent comment if this is a reply"
      field :puzzle, PuzzleType, null: false, description: "The puzzle this comment is on"
      field :replies, [ CommentType ], null: false, description: "Direct replies to this comment"
      field :user, UserType, null: false, description: "User who posted the comment"

      # Live, batched: a commenter who solves after posting still gets the badge.
      def commenter_solved
        context.dataloader.with(Sources::PuzzleSolve, object.puzzle_id).load(object.user_id)
      end

      def is_author
        puzzle = context.dataloader.with(Sources::Record, Puzzle).load(object.puzzle_id)
        puzzle&.author_id == object.user_id
      end
    end
  end
end
