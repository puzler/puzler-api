module Mutations
  module Social
    class CreateComment < Mutations::BaseMutation
      description "Post a comment on a published puzzle"

      argument :body, String, required: true,
        description: "Comment text"
      argument :parent_id, ID, required: false,
        description: "ID of the parent comment to reply to; omit for a top-level comment"
      argument :puzzle_id, ID, required: true,
        description: "ID of the puzzle being commented on"

      field :comment, Types::Objects::CommentType, null: true,
        description: "The newly created comment"
      field :errors, [ String ], null: false,
        description: "Validation errors, if any"

      def resolve(puzzle_id:, body:, parent_id: nil)
        require_auth!
        puzzle = Puzzle.published_or_featured.find_by(id: puzzle_id)
        raise GraphQL::ExecutionError, "Puzzle not found" unless puzzle

        comment = current_user.comments.build(puzzle:, body:, parent_id:)
        if comment.save
          { comment:, errors: [] }
        else
          { comment: nil, errors: comment.errors.full_messages }
        end
      end
    end
  end
end
