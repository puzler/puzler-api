module Mutations
  module Social
    # Flag or unflag a whole comment as a spoiler. Commenters manage their own
    # flag; the puzzle's author (and admins) can moderate any comment on the
    # puzzle. A commenter cannot strip a flag someone else applied.
    class SetCommentSpoiler < Mutations::BaseMutation
      description "Mark or unmark a comment as a spoiler, hidden from viewers who have not solved the puzzle"

      argument :id, ID, required: true,
        description: "ID of the comment"
      argument :spoiler, Boolean, required: true,
        description: "True to mark as a spoiler, false to unmark"

      field :comment, Types::Objects::CommentType, null: true,
        description: "The updated comment"
      field :errors, [ String ], null: false,
        description: "Validation errors, if any"

      def resolve(id:, spoiler:)
        require_auth!
        comment = Comment.find_by(id:)
        raise GraphQL::ExecutionError, "Comment not found" unless comment && may_moderate?(comment)

        if !spoiler && comment.spoiler? && !may_unmark?(comment)
          return { comment: nil, errors: [ "Only the person who marked this spoiler can unmark it" ] }
        end

        comment.update!(spoiler:, spoiler_marked_by: spoiler ? current_user : nil)
        { comment:, errors: [] }
      end

      private

      def may_moderate?(comment)
        current_user.admin? ||
          comment.user_id == current_user.id ||
          comment.puzzle.author_id == current_user.id
      end

      # The commenter may only remove a flag they applied themselves; author or
      # admin moderation flags stay until the moderator (or an admin) lifts them.
      def may_unmark?(comment)
        return true if current_user.admin?
        return true if comment.spoiler_marked_by_id == current_user.id

        comment.puzzle.author_id == current_user.id && comment.user_id != current_user.id
      end
    end
  end
end
